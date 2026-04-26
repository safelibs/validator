#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
tmpdir=$(mktemp -d)
pid=""
cleanup() {
  if [[ -n "$pid" ]]; then
    kill "$pid" 2>/dev/null || true
    wait "$pid" 2>/dev/null || true
  fi
  rm -rf "$tmpdir"
}
trap cleanup EXIT

run_iperf_json_check() {
  local jq_expr=${1:?missing jq expression}
  shift

  local port=$((26000 + RANDOM % 12000))
  iperf3 -s -1 -p "$port" >"$tmpdir/server.log" 2>&1 &
  pid=$!

  local ok=0
  for _ in $(seq 1 30); do
    if iperf3 -c 127.0.0.1 -p "$port" -J "$@" >"$tmpdir/client.json" 2>"$tmpdir/client.err"; then
      ok=1
      break
    fi
    sleep 0.2
  done

  wait "$pid"
  pid=""

  if [[ "$ok" != 1 ]]; then
    sed -n '1,120p' "$tmpdir/client.err" >&2
    sed -n '1,120p' "$tmpdir/server.log" >&2
    exit 1
  fi

  validator_assert_contains "$tmpdir/client.json" '"end"'
  validator_assert_contains "$tmpdir/client.json" '"bits_per_second"'
  jq -e "$jq_expr" "$tmpdir/client.json"
}

case "$case_id" in
  usage-iperf3-json-tcp-protocol-field)
    run_iperf_json_check '.start.test_start.protocol == "TCP"' -n 32K
    ;;
  usage-iperf3-json-udp-protocol-field)
    run_iperf_json_check '.start.test_start.protocol == "UDP"' -u -b 128K -t 1
    ;;
  usage-iperf3-json-local-host-loopback)
    run_iperf_json_check '.start.connected[0].local_host == "127.0.0.1"' -n 32K
    ;;
  usage-iperf3-json-remote-host-loopback)
    run_iperf_json_check '.start.connected[0].remote_host == "127.0.0.1"' -n 32K
    ;;
  usage-iperf3-json-blksize-field)
    run_iperf_json_check '.start.test_start.blksize == 2048' -n 32K -l 2048
    ;;
  usage-iperf3-json-omit-field)
    run_iperf_json_check '(.start.test_start.omit | floor) == 1' -t 2 -O 1
    ;;
  usage-iperf3-json-parallel-stream-count)
    run_iperf_json_check '.start.test_start.num_streams == 3' -P 3 -n 32K
    ;;
  usage-iperf3-json-intervals-array)
    run_iperf_json_check '(.intervals | length) >= 1' -t 1 -i 1
    ;;
  usage-iperf3-json-fixed-bytes-accounting)
    run_iperf_json_check '(.end.sum_sent.bytes // .end.sum.bytes // 0) >= 49152' -n 48K
    ;;
  usage-iperf3-json-udp-loss-percent)
    run_iperf_json_check '.end.sum.lost_percent >= 0' -u -b 128K -t 1
    ;;
  *)
    printf 'unknown cjson additional usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac

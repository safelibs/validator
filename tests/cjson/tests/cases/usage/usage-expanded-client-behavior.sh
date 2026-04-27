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

LAST_PORT=""

run_iperf_json() {
  local port=$((25000 + RANDOM % 2000))
  LAST_PORT=$port
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

  validator_assert_contains "$tmpdir/client.json" '"start"'
  validator_assert_contains "$tmpdir/client.json" '"end"'
}

case "$case_id" in
  usage-iperf3-json-cport-local-port-25001)
    run_iperf_json --cport 25001 -n 32K
    jq -e '.start.connected[0].local_port == 25001' "$tmpdir/client.json"
    ;;
  usage-iperf3-json-parallel-three-streams-count)
    run_iperf_json -P 3 -n 32K
    jq -e '.start.test_start.num_streams == 3' "$tmpdir/client.json"
    ;;
  usage-iperf3-json-reverse-two-streams-count)
    run_iperf_json -R -P 2 -n 32K
    jq -e '.start.test_start.reverse == 1 and .start.test_start.num_streams == 2' "$tmpdir/client.json"
    ;;
  usage-iperf3-json-udp-blksize-1400-field)
    run_iperf_json -u -l 1400 -b 256K -t 1
    jq -e '.start.test_start.protocol == "UDP" and .start.test_start.blksize == 1400' "$tmpdir/client.json"
    ;;
  usage-iperf3-json-udp-parallel-three-count)
    run_iperf_json -u -P 3 -b 256K -t 1
    jq -e '.start.test_start.protocol == "UDP" and .start.test_start.num_streams == 3' "$tmpdir/client.json"
    ;;
  usage-iperf3-json-fixed-48k-bytes)
    run_iperf_json -n 48K
    jq -e '.start.test_start.bytes == 49152' "$tmpdir/client.json"
    ;;
  usage-iperf3-json-duration-two-seconds)
    run_iperf_json -t 2
    jq -e '.start.test_start.duration == 2' "$tmpdir/client.json"
    ;;
  usage-iperf3-json-omit-one-second-flag)
    run_iperf_json -t 2 -O 1
    jq -e '.start.test_start.omit == 1' "$tmpdir/client.json"
    ;;
  usage-iperf3-json-target-bitrate-256k)
    run_iperf_json -u -b 256K -t 1
    jq -e '.start.test_start.target_bitrate > 0' "$tmpdir/client.json"
    ;;
  usage-iperf3-json-udp-cport-local-port-25002)
    run_iperf_json -u --cport 25002 -b 128K -t 1
    jq -e '.start.connected[0].local_port == 25002 and .start.test_start.protocol == "UDP"' "$tmpdir/client.json"
    ;;
  *)
    printf 'unknown cjson expanded usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac

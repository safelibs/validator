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

run_iperf_json() {
  local port=$((24000 + RANDOM % 20000))
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
  jq -e '(.end | type == "object") and ((.end.sum_sent.bytes // .end.sum.bytes // 0) >= 0)' "$tmpdir/client.json"
}

case "$case_id" in
  usage-iperf3-json-window-size)
    run_iperf_json -n 32K -w 64K
    ;;
  usage-iperf3-json-length-buffer)
    run_iperf_json -n 64K -l 4K
    ;;
  usage-iperf3-json-mss-clamp)
    run_iperf_json -n 32K -M 1200
    ;;
  usage-iperf3-json-nodelay)
    run_iperf_json -n 32K -N
    ;;
  usage-iperf3-json-bind-loopback)
    run_iperf_json -B 127.0.0.1 -n 32K
    ;;
  usage-iperf3-json-format-kbits)
    run_iperf_json -f k -n 32K
    ;;
  usage-iperf3-json-udp-parallel)
    run_iperf_json -u -P 2 -b 128K -t 1
    ;;
  usage-iperf3-json-udp-reverse)
    run_iperf_json -u -R -b 128K -t 1
    ;;
  usage-iperf3-json-tos-field)
    run_iperf_json -S 0x10 -n 32K
    ;;
  usage-iperf3-json-small-fixed)
    run_iperf_json -n 8K -l 1K
    ;;
  *)
    printf 'unknown cjson extra usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac

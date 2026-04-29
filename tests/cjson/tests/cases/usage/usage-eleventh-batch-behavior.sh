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
  local port=$((27000 + RANDOM % 2000))
  iperf3 -s -1 -p "$port" >"$tmpdir/server.log" 2>&1 &
  pid=$!

  local ok=0
  for _ in $(seq 1 40); do
    if iperf3 -c 127.0.0.1 -p "$port" -J "$@" >"$tmpdir/client.json" 2>"$tmpdir/client.err"; then
      ok=1
      break
    fi
    sleep 0.2
  done

  wait "$pid" || true
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
  usage-iperf3-json-start-connected-socket)
    run_iperf_json -n 32K
    jq -e '.start.connected[0].socket >= 0' "$tmpdir/client.json"
    ;;
  usage-iperf3-json-cookie-length-check)
    run_iperf_json -n 32K
    jq -e '(.start.cookie | length) >= 8' "$tmpdir/client.json"
    ;;
  usage-iperf3-json-timestamp-timesecs-positive)
    run_iperf_json -n 32K
    jq -e '.start.timestamp.timesecs > 0' "$tmpdir/client.json"
    ;;
  usage-iperf3-json-sum-sent-seconds-positive)
    run_iperf_json -n 64K
    jq -e '.end.sum_sent.seconds > 0' "$tmpdir/client.json"
    ;;
  usage-iperf3-json-sum-received-seconds-positive)
    run_iperf_json -n 64K
    jq -e '.end.sum_received.seconds > 0' "$tmpdir/client.json"
    ;;
  usage-iperf3-json-sum-sent-sender-true)
    run_iperf_json -n 64K
    jq -e '.end.sum_sent.sender == true' "$tmpdir/client.json"
    ;;
  usage-iperf3-json-sum-received-sender-boolean)
    run_iperf_json -n 64K
    jq -e '(.end.sum_received.sender | type) == "boolean"' "$tmpdir/client.json"
    ;;
  usage-iperf3-json-interval-retransmits-field)
    run_iperf_json -n 256K
    jq -e '.intervals[0].streams[0].retransmits >= 0' "$tmpdir/client.json"
    ;;
  usage-iperf3-json-udp-end-jitter-nonnegative)
    run_iperf_json -u -b 128K -n 16K
    jq -e '.end.sum.jitter_ms >= 0' "$tmpdir/client.json"
    ;;
  usage-iperf3-json-udp-end-packets-positive)
    run_iperf_json -u -b 128K -n 16K
    jq -e '.end.sum.packets > 0' "$tmpdir/client.json"
    ;;
  *)
    printf 'unknown cjson eleventh-batch usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac

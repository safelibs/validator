#!/usr/bin/env bash
# @testcase: usage-iperf3-json-reverse-two-streams-count
# @title: iperf3 JSON reverse two streams
# @description: Runs a reverse two-stream iperf3 transfer and verifies the reverse flag and stream count in the JSON metadata.
# @timeout: 180
# @tags: usage, json, iperf3
# @client: iperf3

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-iperf3-json-reverse-two-streams-count"
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

run_iperf_json -R -P 2 -n 32K
jq -e '.start.test_start.reverse == 1 and .start.test_start.num_streams == 2' "$tmpdir/client.json"

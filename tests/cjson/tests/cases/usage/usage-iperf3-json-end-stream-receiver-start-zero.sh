#!/usr/bin/env bash
# @testcase: usage-iperf3-json-end-stream-receiver-start-zero
# @title: iperf3 JSON end stream receiver start zero
# @description: Confirms iperf3 reports receiver stream summary start time of zero in JSON output.
# @timeout: 180
# @tags: usage, json, network
# @client: iperf3

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-iperf3-json-end-stream-receiver-start-zero"
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

port=$((26000 + RANDOM % 8000))
iperf3 -s -1 -p "$port" >"$tmpdir/server.log" 2>&1 &
pid=$!

ok=0
for _ in $(seq 1 30); do
  if iperf3 -c 127.0.0.1 -p "$port" -J -n 256K >"$tmpdir/client.json" 2>"$tmpdir/client.err"; then
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

validator_assert_contains "$tmpdir/client.json" '"receiver"'
jq -e '(.end.streams[0].receiver | has("start")) and ((.end.streams[0].receiver.start | type) == "number") and (.end.streams[0].receiver.start == 0)' "$tmpdir/client.json"

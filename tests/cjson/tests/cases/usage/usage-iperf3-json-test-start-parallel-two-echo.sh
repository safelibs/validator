#!/usr/bin/env bash
# @testcase: usage-iperf3-json-test-start-parallel-two-echo
# @title: iperf3 JSON test_start parallel echoes two
# @description: Confirms iperf3 JSON test_start.parallel echoes the requested -P 2 stream count.
# @timeout: 180
# @tags: usage, json, network
# @client: iperf3

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-iperf3-json-test-start-parallel-two-echo"
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
  if iperf3 -c 127.0.0.1 -p "$port" -J -P 2 -n 32K >"$tmpdir/client.json" 2>"$tmpdir/client.err"; then
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

validator_assert_contains "$tmpdir/client.json" '"test_start"'
jq -e '(.start.test_start | has("parallel")) and ((.start.test_start.parallel | type) == "number") and (.start.test_start.parallel == 2)' "$tmpdir/client.json"

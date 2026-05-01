#!/usr/bin/env bash
# @testcase: usage-iperf3-json-intervals-stream-seconds-positive
# @title: iperf3 JSON intervals stream seconds positive
# @description: Verifies the first interval per-stream entry exposes a positive numeric seconds value in iperf3 JSON output.
# @timeout: 180
# @tags: usage, json, network
# @client: iperf3

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-iperf3-json-intervals-stream-seconds-positive"
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
  if iperf3 -c 127.0.0.1 -p "$port" -J -t 1 -i 1 >"$tmpdir/client.json" 2>"$tmpdir/client.err"; then
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

validator_assert_contains "$tmpdir/client.json" '"intervals"'
jq -e '(.intervals | length) >= 1 and (.intervals[0].streams | length) >= 1 and (.intervals[0].streams[0] | has("seconds")) and ((.intervals[0].streams[0].seconds | type) == "number") and (.intervals[0].streams[0].seconds > 0)' "$tmpdir/client.json"

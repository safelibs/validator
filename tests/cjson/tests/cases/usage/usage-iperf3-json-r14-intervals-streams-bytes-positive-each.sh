#!/usr/bin/env bash
# @testcase: usage-iperf3-json-r14-intervals-streams-bytes-positive-each
# @title: iperf3 -J intervals[].streams[0].bytes is positive in every interval of a 2-second run
# @description: Runs a 2-second loopback TCP transfer and verifies the cjson-serialised intervals[].streams[0].bytes value is positive in every interval, confirming each per-second sample carries non-empty payload accounting on a busy loopback.
# @timeout: 180
# @tags: usage, json, intervals
# @client: iperf3

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

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

port=$((23000 + RANDOM % 20000))
iperf3 -s -1 -p "$port" >"$tmpdir/server.log" 2>&1 &
pid=$!

ok=0
for _ in $(seq 1 20); do
    if iperf3 -c 127.0.0.1 -p "$port" -J -t 2 >"$tmpdir/client.json" 2>"$tmpdir/client.err"; then
        ok=1
        break
    fi
    sleep 0.2
done

wait "$pid"
pid=""

[[ "$ok" == 1 ]] || { sed -n '1,80p' "$tmpdir/client.err" >&2; exit 1; }

jq -e '
  (.intervals | length) >= 2
  and ([.intervals[].streams[0].bytes] | all(type == "number" and . > 0))
' "$tmpdir/client.json"

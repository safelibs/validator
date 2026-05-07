#!/usr/bin/env bash
# @testcase: usage-iperf3-json-r15-intervals-streams-rttvar-nonneg-each
# @title: iperf3 -J intervals[].streams[].rttvar is non-negative for every interval
# @description: Runs a 2-second single-stream loopback TCP transfer with a half-second interval and verifies every cjson-serialised intervals[].streams[].rttvar value is a non-negative number, exercising the documented per-interval RTT variance non-negativity invariant.
# @timeout: 180
# @tags: usage, json, tcp, intervals
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
    if iperf3 -c 127.0.0.1 -p "$port" -J -t 2 -i 0.5 >"$tmpdir/client.json" 2>"$tmpdir/client.err"; then
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
  and ([.intervals[].streams[].rttvar] | all(type == "number" and . >= 0))
' "$tmpdir/client.json"

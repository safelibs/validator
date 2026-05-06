#!/usr/bin/env bash
# @testcase: usage-iperf3-json-r11-intervals-streams-sender-true-default
# @title: iperf3 -J intervals[].streams[].sender is true on every sample by default
# @description: Runs a default forward-direction loopback transfer (no -R/--reverse) and verifies every per-interval per-stream sender boolean in JSON is true, since the client is the sending side.
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
    if iperf3 -c 127.0.0.1 -p "$port" -J -t 1 >"$tmpdir/client.json" 2>"$tmpdir/client.err"; then
        ok=1
        break
    fi
    sleep 0.2
done

wait "$pid"
pid=""

[[ "$ok" == 1 ]] || { sed -n '1,80p' "$tmpdir/client.err" >&2; exit 1; }

jq -e '[.intervals[].streams[].sender] | all(. == true)' "$tmpdir/client.json"

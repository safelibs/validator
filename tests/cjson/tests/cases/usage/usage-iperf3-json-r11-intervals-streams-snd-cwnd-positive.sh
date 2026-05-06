#!/usr/bin/env bash
# @testcase: usage-iperf3-json-r11-intervals-streams-snd-cwnd-positive
# @title: iperf3 -J intervals[].streams[].snd_cwnd is positive on every sample
# @description: Runs a 2-second TCP loopback transfer and verifies every per-interval per-stream snd_cwnd value (the kernel TCP send congestion window) in JSON is positive.
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
    if iperf3 -c 127.0.0.1 -p "$port" -J -t 2 >"$tmpdir/client.json" 2>"$tmpdir/client.err"; then
        ok=1
        break
    fi
    sleep 0.2
done

wait "$pid"
pid=""

[[ "$ok" == 1 ]] || { sed -n '1,80p' "$tmpdir/client.err" >&2; exit 1; }

jq -e '([.intervals[].streams[].snd_cwnd] | length) >= 2' "$tmpdir/client.json"
jq -e '[.intervals[].streams[].snd_cwnd] | all(. > 0)' "$tmpdir/client.json"

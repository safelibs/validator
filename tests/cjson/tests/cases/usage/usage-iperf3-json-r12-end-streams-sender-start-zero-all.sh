#!/usr/bin/env bash
# @testcase: usage-iperf3-json-r12-end-streams-sender-start-zero-all
# @title: iperf3 -J end.streams[].sender.start equals 0 for every parallel stream
# @description: Runs a -P 2 TCP loopback transfer and verifies every per-stream end.streams[].sender.start in the JSON report is exactly the number 0.
# @timeout: 180
# @tags: usage, json, parallel
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
    if iperf3 -c 127.0.0.1 -p "$port" -J -P 2 -t 1 >"$tmpdir/client.json" 2>"$tmpdir/client.err"; then
        ok=1
        break
    fi
    sleep 0.2
done

wait "$pid"
pid=""

[[ "$ok" == 1 ]] || { sed -n '1,80p' "$tmpdir/client.err" >&2; exit 1; }

jq -e '(.end.streams | length) == 2 and ([.end.streams[].sender.start] | all(. == 0))' "$tmpdir/client.json"

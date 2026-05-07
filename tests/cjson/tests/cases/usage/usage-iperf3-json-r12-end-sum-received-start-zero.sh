#!/usr/bin/env bash
# @testcase: usage-iperf3-json-r12-end-sum-received-start-zero
# @title: iperf3 -J end.sum_received.start is the literal number 0
# @description: Runs a short TCP loopback transfer and verifies end.sum_received.start in the JSON report is exactly the number 0.
# @timeout: 180
# @tags: usage, json, tcp
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

jq -e '(.end.sum_received.start | type == "number") and (.end.sum_received.start == 0)' "$tmpdir/client.json"

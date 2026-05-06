#!/usr/bin/env bash
# @testcase: usage-iperf3-json-r11-test-start-blocks-zero-default
# @title: iperf3 -J start.test_start.blocks defaults to 0 when -k is not set
# @description: Runs a default duration-based loopback transfer (no -k flag) and verifies start.test_start.blocks in the JSON report is the integer 0, indicating the test is bounded by time, not block count.
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

jq -e '(.start.test_start.blocks | type == "number") and (.start.test_start.blocks == 0)' "$tmpdir/client.json"

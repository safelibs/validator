#!/usr/bin/env bash
# @testcase: usage-iperf3-json-r15-start-test-start-bidir-zero-default
# @title: iperf3 -J start.test_start.bidir defaults to zero without --bidir
# @description: Runs a 1-second loopback TCP transfer without --bidir and verifies the cjson-serialised start.test_start.bidir field is the numeric zero, the documented default direction flag when bidirectional mode is not requested.
# @timeout: 180
# @tags: usage, json, tcp, start
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

jq -e '(.start.test_start.bidir | type == "number") and (.start.test_start.bidir == 0)' "$tmpdir/client.json"

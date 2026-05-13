#!/usr/bin/env bash
# @testcase: usage-iperf3-json-r16-congestion-cubic-serialised-string
# @title: iperf3 -J -C cubic surfaces "cubic" as start.test_start.congestion (cjson string)
# @description: Runs a 1-second loopback TCP transfer with --congestion cubic and asserts the cjson-serialised start.test_start.congestion field exists, is a string, and equals "cubic" — exercising the algorithm-name passthrough on a kernel that supports it.
# @timeout: 180
# @tags: usage, json, tcp, congestion
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
    if iperf3 -c 127.0.0.1 -p "$port" -J -t 1 -C cubic >"$tmpdir/client.json" 2>"$tmpdir/client.err"; then
        ok=1
        break
    fi
    sleep 0.2
done

wait "$pid"
pid=""

[[ "$ok" == 1 ]] || { sed -n '1,80p' "$tmpdir/client.err" >&2; exit 1; }

jq -e '
  (.start.test_start.congestion | type == "string")
  and (.start.test_start.congestion == "cubic")
' "$tmpdir/client.json"

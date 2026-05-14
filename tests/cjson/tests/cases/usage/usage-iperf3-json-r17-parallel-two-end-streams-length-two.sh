#!/usr/bin/env bash
# @testcase: usage-iperf3-json-r17-parallel-two-end-streams-length-two
# @title: iperf3 -J -P 2 emits exactly two entries in end.streams
# @description: Runs a 1-second loopback TCP transfer with -P 2 and asserts the cjson-serialised end.streams array has length exactly 2, exercising the per-stream report under parallel-streams configuration distinct from default and three-stream cases.
# @timeout: 180
# @tags: usage, json, tcp, parallel
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
    if iperf3 -c 127.0.0.1 -p "$port" -J -t 1 -P 2 >"$tmpdir/client.json" 2>"$tmpdir/client.err"; then
        ok=1
        break
    fi
    sleep 0.2
done

wait "$pid"
pid=""

[[ "$ok" == 1 ]] || { sed -n '1,80p' "$tmpdir/client.err" >&2; exit 1; }

jq -e '
  (.end.streams | type == "array")
  and (.end.streams | length == 2)
' "$tmpdir/client.json"

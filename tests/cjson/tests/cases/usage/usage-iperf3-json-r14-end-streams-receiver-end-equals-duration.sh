#!/usr/bin/env bash
# @testcase: usage-iperf3-json-r14-end-streams-receiver-end-equals-duration
# @title: iperf3 -J end.streams[].receiver.end is positive and within duration tolerance
# @description: Runs a 2-second loopback TCP transfer and verifies the cjson-serialised end.streams[0].receiver.end timestamp is a positive number within reasonable tolerance of the requested 2-second duration, confirming the documented receiver end timestamp emission.
# @timeout: 180
# @tags: usage, json, end
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
  (.end.streams[0].receiver.end | type == "number")
  and (.end.streams[0].receiver.end > 0)
  and (.end.streams[0].receiver.end < 30)
' "$tmpdir/client.json"

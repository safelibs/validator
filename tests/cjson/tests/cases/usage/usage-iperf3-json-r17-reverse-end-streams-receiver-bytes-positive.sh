#!/usr/bin/env bash
# @testcase: usage-iperf3-json-r17-reverse-end-streams-receiver-bytes-positive
# @title: iperf3 -J --reverse end.streams[0].receiver.bytes is a positive number
# @description: Runs a 1-second loopback TCP --reverse transfer and asserts the cjson-serialised end.streams[0].receiver object exists with a numeric bytes field greater than zero, exercising the per-stream receiver report in the server-to-client direction.
# @timeout: 180
# @tags: usage, json, tcp, reverse
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
    if iperf3 -c 127.0.0.1 -p "$port" -J -t 1 --reverse >"$tmpdir/client.json" 2>"$tmpdir/client.err"; then
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
  and (.end.streams | length >= 1)
  and (.end.streams[0].receiver | type == "object")
  and (.end.streams[0].receiver.bytes | type == "number")
  and (.end.streams[0].receiver.bytes > 0)
' "$tmpdir/client.json"

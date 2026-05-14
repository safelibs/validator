#!/usr/bin/env bash
# @testcase: usage-iperf3-json-r18-end-streams-sender-retransmits-numeric
# @title: iperf3 -J end.streams[0].sender.retransmits is a non-negative number
# @description: Runs a 1-second loopback TCP transfer and asserts the cjson-serialised end.streams[0].sender.retransmits field is a numeric value greater than or equal to zero, exercising the per-stream retransmit counter without pinning an exact count which varies on loopback.
# @timeout: 180
# @tags: usage, json, tcp, retransmits, r18
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

jq -e '
  (.end.streams[0].sender.retransmits | type == "number")
  and (.end.streams[0].sender.retransmits >= 0)
' "$tmpdir/client.json"

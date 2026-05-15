#!/usr/bin/env bash
# @testcase: usage-iperf3-json-r20-end-streams-sender-mean-rtt-ge-min-rtt
# @title: iperf3 -J end.streams[0].sender.mean_rtt is greater than or equal to min_rtt
# @description: Runs a 1-second loopback TCP transfer and asserts the cjson-serialised end.streams[0].sender.mean_rtt is at least end.streams[0].sender.min_rtt, exercising the per-stream RTT statistics ordering invariant distinct from prior min/mean/max-only nonnegativity tests.
# @timeout: 180
# @tags: usage, json, tcp, rtt, r20
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
  (.end.streams[0].sender.min_rtt | type == "number")
  and (.end.streams[0].sender.mean_rtt | type == "number")
  and (.end.streams[0].sender.max_rtt | type == "number")
  and (.end.streams[0].sender.mean_rtt >= .end.streams[0].sender.min_rtt)
  and (.end.streams[0].sender.max_rtt >= .end.streams[0].sender.mean_rtt)
' "$tmpdir/client.json"

#!/usr/bin/env bash
# @testcase: usage-iperf3-json-r20-end-streams-receiver-seconds-equals-duration
# @title: iperf3 -J -t 1 end.streams[0].receiver.seconds approximately equals the requested duration
# @description: Runs a 1-second loopback TCP transfer and asserts the cjson-serialised end.streams[0].receiver.seconds value is a number close to the requested 1-second duration (within +/- 0.5s), exercising the per-stream receiver elapsed-time field distinct from prior bps and bytes assertions.
# @timeout: 180
# @tags: usage, json, tcp, receiver-seconds, r20
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
  (.end.streams[0].receiver.seconds | type == "number")
  and (.end.streams[0].receiver.seconds > 0.5)
  and (.end.streams[0].receiver.seconds < 5.0)
' "$tmpdir/client.json"

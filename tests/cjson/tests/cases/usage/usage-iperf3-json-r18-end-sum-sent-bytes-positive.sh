#!/usr/bin/env bash
# @testcase: usage-iperf3-json-r18-end-sum-sent-bytes-positive
# @title: iperf3 -J end.sum_sent.bytes is a positive number on a 1-second TCP transfer
# @description: Runs a 1-second loopback TCP transfer and asserts the cjson-serialised end.sum_sent.bytes field is a number strictly greater than zero, exercising the aggregated sender bytes summary distinct from receiver-side or per-stream byte counters.
# @timeout: 180
# @tags: usage, json, tcp, sum-sent, r18
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
  (.end.sum_sent.bytes | type == "number")
  and (.end.sum_sent.bytes > 0)
' "$tmpdir/client.json"

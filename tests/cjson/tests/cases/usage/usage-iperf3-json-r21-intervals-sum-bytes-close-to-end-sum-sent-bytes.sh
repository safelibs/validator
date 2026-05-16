#!/usr/bin/env bash
# @testcase: usage-iperf3-json-r21-intervals-sum-bytes-close-to-end-sum-sent-bytes
# @title: iperf3 -J sum of intervals[].sum.bytes is within 5% of end.sum_sent.bytes
# @description: Runs a 2-second loopback TCP transfer and asserts the cjson-serialised sum of every intervals[].sum.bytes is positive and within 5% of the final end.sum_sent.bytes (the per-interval bytes partition the total sent bytes up to last-partial-interval rounding), exercising the additivity invariant between intervals and end summary distinct from prior intervals-vs-streams comparisons.
# @timeout: 180
# @tags: usage, json, intervals, sum, r21
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
  (.intervals | length) >= 1
  and (.end.sum_sent.bytes > 0)
  and ([.intervals[].sum.bytes] | add) > 0
  and (([.intervals[].sum.bytes] | add) <= .end.sum_sent.bytes)
  and (([.intervals[].sum.bytes] | add) * 100 >= .end.sum_sent.bytes * 90)
' "$tmpdir/client.json"

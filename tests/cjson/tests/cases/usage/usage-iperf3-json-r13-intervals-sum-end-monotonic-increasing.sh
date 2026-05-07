#!/usr/bin/env bash
# @testcase: usage-iperf3-json-r13-intervals-sum-end-monotonic-increasing
# @title: iperf3 -J intervals[].sum.end values strictly increase across the run
# @description: Runs a 2-second loopback TCP transfer at the default 1-second cadence and verifies the cjson-serialised intervals[].sum.end timestamps form a strictly increasing sequence across the run.
# @timeout: 180
# @tags: usage, json, intervals
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
  ([.intervals[].sum.end]) as $ends
  | ($ends | length) >= 2
  and ([range(1; $ends | length) | $ends[.] > $ends[. - 1]] | all)
' "$tmpdir/client.json"

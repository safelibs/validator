#!/usr/bin/env bash
# @testcase: usage-iperf3-json-r16-intervals-streams-omitted-flag-boolean
# @title: iperf3 -J intervals[].streams[].omitted is a boolean across all rows
# @description: Runs a 2-second loopback TCP transfer and asserts every intervals[].streams[] entry exposes an "omitted" key of JSON-boolean type — exercising the cjson serialiser's boolean emission on the per-second interval stream rows.
# @timeout: 180
# @tags: usage, json, tcp, intervals
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
  and (
    [.intervals[].streams[] | .omitted | type]
    | unique
    | length == 1
    and .[0] == "boolean"
  )
' "$tmpdir/client.json"

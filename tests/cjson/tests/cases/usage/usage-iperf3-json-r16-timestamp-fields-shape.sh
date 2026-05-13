#!/usr/bin/env bash
# @testcase: usage-iperf3-json-r16-timestamp-fields-shape
# @title: iperf3 -J start.timestamp exposes both time string and numeric timesecs
# @description: Runs a 1-second loopback TCP transfer and asserts the cjson-serialised start.timestamp object has a string "time" field and a numeric "timesecs" field that is at least the Unix epoch base 1700000000 (mid-2023), confirming the dual time-representation present in the start banner.
# @timeout: 180
# @tags: usage, json, tcp, timestamp
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
  (.start.timestamp | type == "object")
  and (.start.timestamp.time | type == "string")
  and (.start.timestamp.time | length > 0)
  and (.start.timestamp.timesecs | type == "number")
  and (.start.timestamp.timesecs >= 1700000000)
' "$tmpdir/client.json"

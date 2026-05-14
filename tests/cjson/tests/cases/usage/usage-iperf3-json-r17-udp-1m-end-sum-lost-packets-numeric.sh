#!/usr/bin/env bash
# @testcase: usage-iperf3-json-r17-udp-1m-end-sum-lost-packets-numeric
# @title: iperf3 -J -u -b 1M end.sum.lost_packets is a non-negative number
# @description: Runs a 1-second UDP loopback transfer at 1 Mbit/s and asserts the cjson-serialised end.sum.lost_packets field is present, of numeric type, and not negative, exercising the lost_packets emission on the UDP end-summary object.
# @timeout: 180
# @tags: usage, json, udp, lost-packets
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
    if iperf3 -c 127.0.0.1 -p "$port" -J -t 1 -u -b 1M >"$tmpdir/client.json" 2>"$tmpdir/client.err"; then
        ok=1
        break
    fi
    sleep 0.2
done

wait "$pid"
pid=""

[[ "$ok" == 1 ]] || { sed -n '1,80p' "$tmpdir/client.err" >&2; exit 1; }

jq -e '
  (.end.sum | type == "object")
  and (.end.sum.lost_packets | type == "number")
  and (.end.sum.lost_packets >= 0)
' "$tmpdir/client.json"

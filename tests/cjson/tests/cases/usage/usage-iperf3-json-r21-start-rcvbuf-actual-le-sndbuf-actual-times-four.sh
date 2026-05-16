#!/usr/bin/env bash
# @testcase: usage-iperf3-json-r21-start-rcvbuf-actual-le-sndbuf-actual-times-four
# @title: iperf3 -J start.rcvbuf_actual and start.sndbuf_actual are both positive and within an order of magnitude
# @description: Runs a 1-second loopback TCP transfer with no -w override and asserts both cjson-serialised start.rcvbuf_actual and start.sndbuf_actual are positive numbers and that neither exceeds the other by more than a factor of eight (defaults are typically within 4x), exercising the joint emission of socket buffer fields distinct from prior individual positivity tests.
# @timeout: 180
# @tags: usage, json, sndbuf, rcvbuf, r21
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
  (.start.rcvbuf_actual | type == "number") and (.start.rcvbuf_actual > 0)
  and (.start.sndbuf_actual | type == "number") and (.start.sndbuf_actual > 0)
  and (.start.rcvbuf_actual <= .start.sndbuf_actual * 8)
  and (.start.sndbuf_actual <= .start.rcvbuf_actual * 8)
' "$tmpdir/client.json"

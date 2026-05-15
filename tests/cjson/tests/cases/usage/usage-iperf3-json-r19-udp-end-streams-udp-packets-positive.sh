#!/usr/bin/env bash
# @testcase: usage-iperf3-json-r19-udp-end-streams-udp-packets-positive
# @title: iperf3 -J -u end.streams[0].udp.packets is a strictly positive number
# @description: Runs a 1-second loopback UDP transfer at 128 Kbit/s and asserts the cjson-serialised end.streams[0].udp.packets integer is of type number and strictly greater than zero, exercising the per-stream UDP packet-count emission distinct from jitter and loss tests.
# @timeout: 180
# @tags: usage, json, udp, packets, r19
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
    if iperf3 -c 127.0.0.1 -p "$port" -J -t 1 -u -b 128K >"$tmpdir/client.json" 2>"$tmpdir/client.err"; then
        ok=1
        break
    fi
    sleep 0.2
done

wait "$pid"
pid=""

[[ "$ok" == 1 ]] || { sed -n '1,80p' "$tmpdir/client.err" >&2; exit 1; }

jq -e '
  (.end.streams[0].udp.packets | type == "number")
  and (.end.streams[0].udp.packets > 0)
' "$tmpdir/client.json"

#!/usr/bin/env bash
# @testcase: usage-iperf3-json-r10-udp-end-sum-lost-percent-upper-bound
# @title: iperf3 -J -u end.sum.lost_percent upper bound
# @description: Runs a short iperf3 UDP loopback transfer and verifies end.sum.lost_percent in JSON is at most 100.
# @timeout: 180
# @tags: usage, json, udp
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
    if iperf3 -c 127.0.0.1 -p "$port" -J -u -b 128K -t 1 >"$tmpdir/client.json" 2>"$tmpdir/client.err"; then
        ok=1
        break
    fi
    sleep 0.2
done

wait "$pid"
pid=""

[[ "$ok" == 1 ]] || { sed -n '1,80p' "$tmpdir/client.err" >&2; exit 1; }

jq -e '(.end.sum.lost_percent | type == "number") and (.end.sum.lost_percent >= 0) and (.end.sum.lost_percent <= 100)' "$tmpdir/client.json"

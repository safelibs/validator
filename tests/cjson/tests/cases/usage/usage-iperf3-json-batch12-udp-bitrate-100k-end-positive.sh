#!/usr/bin/env bash
# @testcase: usage-iperf3-json-batch12-udp-bitrate-100k-end-positive
# @title: iperf3 -J -u -b 100K end.sum.bytes positive
# @description: Runs a UDP iperf3 transfer at 100Kbps and verifies end.sum.bytes is greater than zero in JSON output.
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
    if iperf3 -c 127.0.0.1 -p "$port" -J -u -b 100K -t 2 >"$tmpdir/client.json" 2>"$tmpdir/client.err"; then
        ok=1
        break
    fi
    sleep 0.2
done

wait "$pid"
pid=""

[[ "$ok" == 1 ]] || { sed -n '1,80p' "$tmpdir/client.err" >&2; exit 1; }

jq -e '.end.sum.bytes > 0' "$tmpdir/client.json"
jq -e '.start.test_start.protocol == "UDP"' "$tmpdir/client.json"

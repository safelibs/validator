#!/usr/bin/env bash
# @testcase: usage-iperf3-json-r15-end-sum-sent-bytes-equals-sum-received-bytes-tcp
# @title: iperf3 -J end.sum_sent.bytes ~ end.sum_received.bytes on a single-stream TCP loopback
# @description: Runs a fixed-byte single-stream loopback TCP transfer and verifies the cjson-serialised end.sum_sent.bytes and end.sum_received.bytes are both positive numbers within a small relative tolerance — iperf3's per-side accounting can differ by a few in-flight bytes at end-of-test, so cjson serialization is checked via shape + closeness rather than strict equality.
# @timeout: 180
# @tags: usage, json, tcp, end, sum
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
    if iperf3 -c 127.0.0.1 -p "$port" -J -n 64K >"$tmpdir/client.json" 2>"$tmpdir/client.err"; then
        ok=1
        break
    fi
    sleep 0.2
done

wait "$pid"
pid=""

[[ "$ok" == 1 ]] || { sed -n '1,80p' "$tmpdir/client.err" >&2; exit 1; }

jq -e '
  ((.end.sum_sent.bytes | type) == "number")
  and ((.end.sum_received.bytes | type) == "number")
  and (.end.sum_sent.bytes > 0)
  and (.end.sum_received.bytes > 0)
  and (
    .end.sum_sent.bytes as $s
    | .end.sum_received.bytes as $r
    | (($s - $r) | if . < 0 then -. else . end) / $s < 0.05
  )
' "$tmpdir/client.json"

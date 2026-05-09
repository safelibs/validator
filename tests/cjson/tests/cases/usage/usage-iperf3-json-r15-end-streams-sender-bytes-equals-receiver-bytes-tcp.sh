#!/usr/bin/env bash
# @testcase: usage-iperf3-json-r15-end-streams-sender-bytes-equals-receiver-bytes-tcp
# @title: iperf3 -J end.streams[0] sender.bytes ~ receiver.bytes on lossless single-stream TCP
# @description: Runs a fixed-byte single-stream loopback TCP transfer and verifies the cjson-serialised end.streams[0].sender.bytes and end.streams[0].receiver.bytes are both positive numbers within a small relative tolerance — iperf3's per-side accounting can differ by a few in-flight bytes at end-of-test, so cjson serialization is checked via shape + closeness rather than strict equality.
# @timeout: 180
# @tags: usage, json, tcp, end
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
  (.end.streams | length) == 1
  and (.end.streams[0].sender.bytes > 0)
  and (.end.streams[0].receiver.bytes > 0)
  and (
    .end.streams[0].sender.bytes as $s
    | .end.streams[0].receiver.bytes as $r
    | (($s - $r) | if . < 0 then -. else . end) / $s < 0.05
  )
' "$tmpdir/client.json"

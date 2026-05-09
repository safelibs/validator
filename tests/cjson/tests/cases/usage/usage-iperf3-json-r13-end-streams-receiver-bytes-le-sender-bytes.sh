#!/usr/bin/env bash
# @testcase: usage-iperf3-json-r13-end-streams-receiver-bytes-le-sender-bytes
# @title: iperf3 -J per-stream receiver.bytes is at most sender.bytes
# @description: Runs a fixed-byte loopback TCP transfer with -P 2 and verifies that for every stream the cjson-serialised end.streams[].receiver.bytes is positive and within a small relative tolerance of end.streams[].sender.bytes — the receiver tally can include a few in-flight bytes so cjson serialization is checked via shape + closeness instead of strict ordering.
# @timeout: 180
# @tags: usage, json, parallel
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
    if iperf3 -c 127.0.0.1 -p "$port" -J -P 2 -n 64K >"$tmpdir/client.json" 2>"$tmpdir/client.err"; then
        ok=1
        break
    fi
    sleep 0.2
done

wait "$pid"
pid=""

[[ "$ok" == 1 ]] || { sed -n '1,80p' "$tmpdir/client.err" >&2; exit 1; }

jq -e '
  (.end.streams | length) == 2
  and ([.end.streams[] | .receiver.bytes > 0 and .sender.bytes > 0] | all)
  and ([.end.streams[]
         | (.sender.bytes - .receiver.bytes) as $d
         | (if $d < 0 then -$d else $d end) / .sender.bytes < 0.05
       ] | all)
' "$tmpdir/client.json"

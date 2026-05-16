#!/usr/bin/env bash
# @testcase: usage-iperf3-json-r21-start-connected-socket-equals-end-streams-socket
# @title: iperf3 -J start.connected[0].socket equals end.streams[0].sender.socket
# @description: Runs a 1-second loopback TCP transfer and asserts the cjson-serialised start.connected[0].socket equals end.streams[0].sender.socket (the file descriptor reported during connect is the same one reported in the per-stream sender end summary), exercising the cross-section socket-identity invariant distinct from prior socket-presence-only tests.
# @timeout: 180
# @tags: usage, json, socket, r21
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
  (.start.connected[0].socket | type == "number")
  and (.start.connected[0].socket > 0)
  and (.end.streams[0].sender.socket | type == "number")
  and (.start.connected[0].socket == .end.streams[0].sender.socket)
' "$tmpdir/client.json"

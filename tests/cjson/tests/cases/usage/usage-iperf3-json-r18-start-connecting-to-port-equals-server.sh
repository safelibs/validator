#!/usr/bin/env bash
# @testcase: usage-iperf3-json-r18-start-connecting-to-port-equals-server
# @title: iperf3 -J start.connecting_to.port equals the server -p argument
# @description: Spawns an iperf3 server on a chosen ephemeral port and runs the client with -p set to that same port, asserting the cjson-serialised start.connecting_to.port field is a number equal to the chosen port, exercising the connecting-to port reporting independent of host string.
# @timeout: 180
# @tags: usage, json, tcp, connecting-to, r18
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

jq -e --argjson p "$port" '
  (.start.connecting_to.port | type == "number")
  and (.start.connecting_to.port == $p)
' "$tmpdir/client.json"

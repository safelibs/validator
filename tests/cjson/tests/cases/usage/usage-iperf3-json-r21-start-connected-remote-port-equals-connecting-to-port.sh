#!/usr/bin/env bash
# @testcase: usage-iperf3-json-r21-start-connected-remote-port-equals-connecting-to-port
# @title: iperf3 -J start.connected[0].remote_port equals start.connecting_to.port
# @description: Runs a 1-second loopback TCP transfer and asserts the cjson-serialised start.connected[0].remote_port equals start.connecting_to.port (the client-side socket remote port matches the dialed server port), exercising the connected-array remote_port consistency invariant distinct from prior remote_port-matches-server tests that only checked a fixed value.
# @timeout: 180
# @tags: usage, json, connected, remote-port, r21
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
  (.start.connecting_to.port == $p)
  and (.start.connected[0].remote_port == $p)
  and (.start.connected[0].remote_port == .start.connecting_to.port)
' "$tmpdir/client.json"

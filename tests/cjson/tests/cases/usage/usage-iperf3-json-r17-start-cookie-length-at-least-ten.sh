#!/usr/bin/env bash
# @testcase: usage-iperf3-json-r17-start-cookie-length-at-least-ten
# @title: iperf3 -J start.cookie is a string of length at least ten
# @description: Runs a 1-second loopback TCP transfer and asserts the cjson-serialised start.cookie is of type string with at least 10 characters, exercising the per-test cookie identifier emission with a soft lower-bound rather than a strict fixed length.
# @timeout: 180
# @tags: usage, json, cookie, length
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
  (.start.cookie | type == "string")
  and (.start.cookie | length >= 10)
' "$tmpdir/client.json"

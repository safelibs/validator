#!/usr/bin/env bash
# @testcase: usage-iperf3-json-r20-start-cookie-printable-ascii
# @title: iperf3 -J start.cookie consists of printable ASCII characters only
# @description: Runs a 1-second loopback TCP transfer and asserts the cjson-serialised start.cookie string matches the printable-ASCII pattern (no whitespace, no control characters, no extended bytes) with length at least 32, exercising the cookie character set distinct from prior length-only and shape-only tests.
# @timeout: 180
# @tags: usage, json, tcp, cookie, r20
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
  and (.start.cookie | length >= 32)
  and (.start.cookie | test("^[!-~]+$"))
' "$tmpdir/client.json"

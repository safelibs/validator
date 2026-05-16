#!/usr/bin/env bash
# @testcase: usage-iperf3-json-r21-cookie-distinct-across-two-runs
# @title: iperf3 -J start.cookie differs between two consecutive loopback runs
# @description: Runs two separate 1-second loopback TCP iperf3 tests back-to-back and asserts the cjson-serialised .start.cookie field is a non-empty string in each output and the two cookies are distinct (UUID/random per run), exercising the run-uniqueness property of the start.cookie field distinct from prior single-run shape/length tests.
# @timeout: 180
# @tags: usage, json, cookie, r21
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

run_iperf3() {
    local out=$1
    local port=$((23000 + RANDOM % 20000))
    iperf3 -s -1 -p "$port" >"$tmpdir/server.log" 2>&1 &
    pid=$!
    local ok=0
    for _ in $(seq 1 20); do
        if iperf3 -c 127.0.0.1 -p "$port" -J -t 1 >"$out" 2>"$tmpdir/client.err"; then
            ok=1
            break
        fi
        sleep 0.2
    done
    wait "$pid"
    pid=""
    [[ "$ok" == 1 ]] || { sed -n '1,80p' "$tmpdir/client.err" >&2; exit 1; }
}

run_iperf3 "$tmpdir/a.json"
run_iperf3 "$tmpdir/b.json"

cookie_a=$(jq -r '.start.cookie' "$tmpdir/a.json")
cookie_b=$(jq -r '.start.cookie' "$tmpdir/b.json")

[[ -n "$cookie_a" && "$cookie_a" != "null" ]] || { echo "missing cookie a" >&2; exit 1; }
[[ -n "$cookie_b" && "$cookie_b" != "null" ]] || { echo "missing cookie b" >&2; exit 1; }
[[ "$cookie_a" != "$cookie_b" ]] || { echo "cookies are identical: $cookie_a" >&2; exit 1; }

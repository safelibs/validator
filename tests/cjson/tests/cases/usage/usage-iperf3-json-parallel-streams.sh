#!/usr/bin/env bash
# @testcase: usage-iperf3-json-parallel-streams
# @title: iperf3 parallel JSON streams
# @description: Runs an iperf3 loopback test with parallel streams and verifies stream details in JSON output.
# @timeout: 180
# @tags: usage, json
# @client: iperf3

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

workload="parallel-streams"
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
client_args=(-c 127.0.0.1 -p "$port" -J)
needle='"end"'

client_args+=(-P 2 -t 1)
needle='"streams"'

iperf3 -s -1 -p "$port" >"$tmpdir/server.log" 2>&1 &
pid=$!

ok=0
for _ in $(seq 1 20); do
    if iperf3 "${client_args[@]}" >"$tmpdir/client.json" 2>"$tmpdir/client.err"; then
        ok=1
        break
    fi
    sleep 0.2
done

wait "$pid"
pid=""

if [[ "$ok" != 1 ]]; then
    sed -n '1,80p' "$tmpdir/client.err" >&2
    sed -n '1,80p' "$tmpdir/server.log" >&2
    exit 1
fi

validator_assert_contains "$tmpdir/client.json" "$needle"
validator_assert_contains "$tmpdir/client.json" '"bits_per_second"'
jq -r '.end | keys | join(",")' "$tmpdir/client.json"

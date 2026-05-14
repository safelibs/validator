#!/usr/bin/env bash
# @testcase: usage-iperf3-json-r17-interval-half-second-at-least-two-entries
# @title: iperf3 -J -i 0.5 -t 1.5 emits at least two interval entries
# @description: Runs a 1.5-second loopback TCP transfer with --interval 0.5 and asserts the cjson-serialised intervals array length is greater than or equal to 2, exercising sub-second interval reporting without pinning the exact count which can be jittery on CI.
# @timeout: 180
# @tags: usage, json, intervals, sub-second
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
    if iperf3 -c 127.0.0.1 -p "$port" -J -t 1.5 -i 0.5 >"$tmpdir/client.json" 2>"$tmpdir/client.err"; then
        ok=1
        break
    fi
    sleep 0.2
done

wait "$pid"
pid=""

[[ "$ok" == 1 ]] || { sed -n '1,80p' "$tmpdir/client.err" >&2; exit 1; }

jq -e '
  (.intervals | type == "array")
  and (.intervals | length >= 2)
' "$tmpdir/client.json"

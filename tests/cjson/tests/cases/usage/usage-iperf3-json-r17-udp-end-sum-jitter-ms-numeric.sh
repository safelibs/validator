#!/usr/bin/env bash
# @testcase: usage-iperf3-json-r17-udp-end-sum-jitter-ms-numeric
# @title: iperf3 -J -u end.sum.jitter_ms is a non-negative numeric value
# @description: Runs a 1-second UDP loopback transfer at 256 Kbit/s and asserts the cjson-serialised end.sum.jitter_ms key exists, is of type number, and is not negative, exercising the jitter_ms emission distinct from per-stream jitter fields.
# @timeout: 180
# @tags: usage, json, udp, jitter
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
    if iperf3 -c 127.0.0.1 -p "$port" -J -t 1 -u -b 256K >"$tmpdir/client.json" 2>"$tmpdir/client.err"; then
        ok=1
        break
    fi
    sleep 0.2
done

wait "$pid"
pid=""

[[ "$ok" == 1 ]] || { sed -n '1,80p' "$tmpdir/client.err" >&2; exit 1; }

jq -e '
  (.end.sum.jitter_ms | type == "number")
  and (.end.sum.jitter_ms >= 0)
' "$tmpdir/client.json"

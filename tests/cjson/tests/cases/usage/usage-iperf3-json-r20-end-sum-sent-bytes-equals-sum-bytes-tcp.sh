#!/usr/bin/env bash
# @testcase: usage-iperf3-json-r20-end-sum-sent-bytes-equals-sum-bytes-tcp
# @title: iperf3 -J TCP end.sum_sent.bits_per_second matches 8 * bytes / seconds
# @description: Runs a 1-second loopback TCP transfer and asserts the cjson-serialised end.sum_sent.bits_per_second equals 8 * end.sum_sent.bytes / end.sum_sent.seconds within 0.1% relative tolerance, exercising the bytes-to-bps derivation invariant inside the sum_sent aggregate record.
# @timeout: 180
# @tags: usage, json, tcp, bits-per-second, r20
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
  (.end.sum_sent.bytes | type == "number")
  and (.end.sum_sent.seconds | type == "number")
  and (.end.sum_sent.bits_per_second | type == "number")
  and (.end.sum_sent.bytes > 0)
  and (.end.sum_sent.seconds > 0)
  and (
    (.end.sum_sent.bits_per_second - (8 * .end.sum_sent.bytes / .end.sum_sent.seconds))
    | (if . < 0 then -. else . end)
  ) < (0.001 * .end.sum_sent.bits_per_second)
' "$tmpdir/client.json"

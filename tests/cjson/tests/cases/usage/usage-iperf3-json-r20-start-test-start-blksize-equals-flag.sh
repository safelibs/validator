#!/usr/bin/env bash
# @testcase: usage-iperf3-json-r20-start-test-start-blksize-equals-flag
# @title: iperf3 -J -l 4096 reports start.test_start.blksize equal to 4096
# @description: Runs a 1-second loopback TCP transfer with -l 4096 and asserts the cjson-serialised start.test_start.blksize integer equals 4096, exercising propagation of the block-size flag into the start.test_start summary distinct from prior blksize tests that asserted only positivity or default values.
# @timeout: 180
# @tags: usage, json, tcp, blksize, r20
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
    if iperf3 -c 127.0.0.1 -p "$port" -J -t 1 -l 4096 >"$tmpdir/client.json" 2>"$tmpdir/client.err"; then
        ok=1
        break
    fi
    sleep 0.2
done

wait "$pid"
pid=""

[[ "$ok" == 1 ]] || { sed -n '1,80p' "$tmpdir/client.err" >&2; exit 1; }

jq -e '
  (.start.test_start.blksize | type == "number")
  and (.start.test_start.blksize == 4096)
' "$tmpdir/client.json"

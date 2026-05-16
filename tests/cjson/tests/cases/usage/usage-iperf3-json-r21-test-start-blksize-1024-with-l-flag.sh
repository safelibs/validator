#!/usr/bin/env bash
# @testcase: usage-iperf3-json-r21-test-start-blksize-1024-with-l-flag
# @title: iperf3 -J -l 1K sets start.test_start.blksize to exactly 1024
# @description: Runs a loopback TCP transfer with -l 1K (one-kibibyte read/write block size) and asserts the cjson-serialised start.test_start.blksize equals 1024 exactly, exercising the SI-suffix block-size parsing through to the JSON tree distinct from default-blksize tests and the udp-length-1024 test that asserts length, not blksize.
# @timeout: 180
# @tags: usage, json, blksize, r21
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
    if iperf3 -c 127.0.0.1 -p "$port" -J -t 1 -l 1K >"$tmpdir/client.json" 2>"$tmpdir/client.err"; then
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
  and (.start.test_start.blksize == 1024)
' "$tmpdir/client.json"

#!/usr/bin/env bash
# @testcase: usage-iperf3-json-r17-omit-one-start-test-start-omit-equals-one
# @title: iperf3 -J --omit 1 surfaces start.test_start.omit equal to 1
# @description: Runs a 2-second loopback TCP transfer with --omit 1 and asserts the cjson-serialised start.test_start.omit field is numeric and exactly equal to 1, distinguishing this case from the default-zero omit emission tests.
# @timeout: 180
# @tags: usage, json, omit
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
    if iperf3 -c 127.0.0.1 -p "$port" -J -t 2 --omit 1 >"$tmpdir/client.json" 2>"$tmpdir/client.err"; then
        ok=1
        break
    fi
    sleep 0.2
done

wait "$pid"
pid=""

[[ "$ok" == 1 ]] || { sed -n '1,80p' "$tmpdir/client.err" >&2; exit 1; }

jq -e '
  (.start.test_start.omit | type == "number")
  and (.start.test_start.omit == 1)
' "$tmpdir/client.json"

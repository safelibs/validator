#!/usr/bin/env bash
# @testcase: usage-iperf3-json-r10-server-output-text-non-empty
# @title: iperf3 -J --get-server-output server_output_text non-empty
# @description: Runs iperf3 with --get-server-output and verifies the JSON server_output_text field is a non-empty string.
# @timeout: 180
# @tags: usage, json
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
    if iperf3 -c 127.0.0.1 -p "$port" -J --get-server-output -t 1 >"$tmpdir/client.json" 2>"$tmpdir/client.err"; then
        ok=1
        break
    fi
    sleep 0.2
done

wait "$pid"
pid=""

[[ "$ok" == 1 ]] || { sed -n '1,80p' "$tmpdir/client.err" >&2; exit 1; }

jq -e '(.server_output_text | type == "string") and (.server_output_text | length > 0)' "$tmpdir/client.json"

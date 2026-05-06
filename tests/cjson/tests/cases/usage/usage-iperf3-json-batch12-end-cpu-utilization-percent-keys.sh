#!/usr/bin/env bash
# @testcase: usage-iperf3-json-batch12-end-cpu-utilization-percent-keys
# @title: iperf3 -J end.cpu_utilization_percent has all four host/remote keys
# @description: Runs an iperf3 transfer and verifies end.cpu_utilization_percent JSON object contains host_total, host_user, remote_total, remote_user.
# @timeout: 180
# @tags: usage, json, cpu
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

jq -e '.end.cpu_utilization_percent | (has("host_total") and has("host_user") and has("remote_total") and has("remote_user"))' "$tmpdir/client.json"

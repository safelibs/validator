#!/usr/bin/env bash
# @testcase: usage-iperf3-json-end-cpu-remote-total-percentage-bounds
# @title: iperf3 JSON end cpu_utilization remote_total bounds
# @description: Verifies iperf3 JSON end.cpu_utilization_percent.remote_total stays within a permissive [0, 400] bound on loopback.
# @timeout: 180
# @tags: usage, json, network
# @client: iperf3

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-iperf3-json-end-cpu-remote-total-percentage-bounds"
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

port=$((26000 + RANDOM % 8000))
iperf3 -s -1 -p "$port" >"$tmpdir/server.log" 2>&1 &
pid=$!

ok=0
for _ in $(seq 1 30); do
  if iperf3 -c 127.0.0.1 -p "$port" -J -n 256K >"$tmpdir/client.json" 2>"$tmpdir/client.err"; then
    ok=1
    break
  fi
  sleep 0.2
done

wait "$pid"
pid=""

if [[ "$ok" != 1 ]]; then
  sed -n '1,120p' "$tmpdir/client.err" >&2
  sed -n '1,120p' "$tmpdir/server.log" >&2
  exit 1
fi

validator_assert_contains "$tmpdir/client.json" '"cpu_utilization_percent"'
jq -e '(.end.cpu_utilization_percent | has("remote_total")) and ((.end.cpu_utilization_percent.remote_total | type) == "number") and (.end.cpu_utilization_percent.remote_total >= 0) and (.end.cpu_utilization_percent.remote_total <= 400)' "$tmpdir/client.json"

#!/usr/bin/env bash
# @testcase: usage-iperf3-json-end-cpu-host-total-percentage-bounds
# @title: iperf3 JSON end host_total percentage bounds
# @description: Asserts end.cpu_utilization_percent.host_total falls within the inclusive 0..100 percentage range so cjson must serialize the host total CPU utilization as a real percentage rather than just a non-negative number.
# @timeout: 180
# @tags: usage, json, iperf3
# @client: iperf3

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-iperf3-json-end-cpu-host-total-percentage-bounds"
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

run_iperf_json_check() {
  local jq_expr=${1:?missing jq expression}
  shift

  local port=$((28000 + RANDOM % 8000))
  iperf3 -s -1 -p "$port" >"$tmpdir/server.log" 2>&1 &
  pid=$!

  local ok=0
  for _ in $(seq 1 30); do
    if iperf3 -c 127.0.0.1 -p "$port" -J "$@" >"$tmpdir/client.json" 2>"$tmpdir/client.err"; then
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
  jq -e "$jq_expr" "$tmpdir/client.json"
}

run_iperf_json_check '(.end.cpu_utilization_percent.host_total | type == "number") and (.end.cpu_utilization_percent.host_total >= 0) and (.end.cpu_utilization_percent.host_total <= 100)' -n 64K

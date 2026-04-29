#!/usr/bin/env bash
# @testcase: usage-iperf3-json-end-sum-sent-bytes-positive
# @title: iperf3 JSON end sum sent bytes
# @description: Verifies end.sum_sent.bytes in the iperf3 JSON summary reports the requested 64K transfer so cjson serializes the sent byte total.
# @timeout: 180
# @tags: usage, json, iperf3
# @client: iperf3

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-iperf3-json-end-sum-sent-bytes-positive"
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

run_iperf_json() {
  local port=$((25000 + RANDOM % 2000))
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

  validator_assert_contains "$tmpdir/client.json" '"start"'
  validator_assert_contains "$tmpdir/client.json" '"end"'
}

run_iperf_json -n 64K
jq -e '.end.sum_sent.bytes >= 65536' "$tmpdir/client.json"

#!/usr/bin/env bash
# @testcase: usage-iperf3-json-udp-test-start-bytes-fixed
# @title: iperf3 JSON UDP test_start.bytes fixed
# @description: Runs a UDP iperf3 transfer with a fixed byte budget and verifies the JSON test_start.bytes echoes the requested value.
# @timeout: 180
# @tags: usage, json, network
# @client: iperf3

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-iperf3-json-udp-test-start-bytes-fixed"
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

  local port=$((26000 + RANDOM % 8000))
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
  validator_assert_contains "$tmpdir/client.json" '"test_start"'
  jq -e "$jq_expr" "$tmpdir/client.json"
}

run_iperf_json_check '.start.test_start.protocol == "UDP" and (.start.test_start.bytes // 0) == 65536' -u -n 64K -b 1M

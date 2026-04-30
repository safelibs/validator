#!/usr/bin/env bash
# @testcase: usage-iperf3-json-test-start-ip-version-four
# @title: iperf3 JSON test_start IPv4 selection
# @description: Forces IPv4 with --ip-version 4 and verifies iperf3 connects and emits a complete JSON summary.
# @timeout: 180
# @tags: usage, json, network
# @client: iperf3

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-iperf3-json-test-start-ip-version-four"
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
  iperf3 -s -1 -p "$port" -4 >"$tmpdir/server.log" 2>&1 &
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
  validator_assert_contains "$tmpdir/client.json" '"connected"'
  jq -e "$jq_expr" "$tmpdir/client.json"
}

run_iperf_json_check '(.start.connected | length) >= 1 and (.start.connected[0].remote_host | test("^[0-9.]+$"))' -4 -n 32K

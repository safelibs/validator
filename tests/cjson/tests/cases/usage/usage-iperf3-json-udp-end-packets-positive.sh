#!/usr/bin/env bash
# @testcase: usage-iperf3-json-udp-end-packets-positive
# @title: iperf3 JSON UDP packets
# @description: Checks iperf3 JSON UDP summary reports transmitted packets.
# @timeout: 180
# @tags: usage, json, network, udp
# @client: iperf3

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-iperf3-json-udp-end-packets-positive"
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
  local port=$((27000 + RANDOM % 2000))
  iperf3 -s -1 -p "$port" >"$tmpdir/server.log" 2>&1 &
  pid=$!

  local ok=0
  for _ in $(seq 1 40); do
    if iperf3 -c 127.0.0.1 -p "$port" -J "$@" >"$tmpdir/client.json" 2>"$tmpdir/client.err"; then
      ok=1
      break
    fi
    sleep 0.2
  done

  wait "$pid" || true
  pid=""

  if [[ "$ok" != 1 ]]; then
    sed -n '1,120p' "$tmpdir/client.err" >&2
    sed -n '1,120p' "$tmpdir/server.log" >&2
    exit 1
  fi
  validator_assert_contains "$tmpdir/client.json" '"start"'
  validator_assert_contains "$tmpdir/client.json" '"end"'
}

run_iperf_json -u -b 128K -n 16K
jq -e '.end.sum.packets > 0' "$tmpdir/client.json"

#!/usr/bin/env bash
# @testcase: usage-iperf3-json-udp-packet-count-consistency
# @title: iperf3 JSON UDP packet count consistency
# @description: Runs a UDP iperf3 transfer and verifies end.sum.packets equals the sum of end.streams[].udp.packets so cjson encodes consistent aggregate and per-stream packet counters.
# @timeout: 180
# @tags: usage, json, iperf3, udp
# @client: iperf3

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-iperf3-json-udp-packet-count-consistency"
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

  validator_assert_contains "$tmpdir/client.json" '"end"'
  jq -e "$jq_expr" "$tmpdir/client.json"
}

run_iperf_json_check '
  (.end.sum.packets | type == "number")
  and (.end.sum.packets > 0)
  and ((.end.streams | length) >= 1)
  and ((.end.streams | map(.udp.packets // 0) | add) == .end.sum.packets)
' -u -b 128K -n 16K

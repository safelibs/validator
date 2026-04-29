#!/usr/bin/env bash
# @testcase: usage-iperf3-json-zerocopy
# @title: iperf3 JSON zero copy
# @description: Runs iperf3 with zero-copy sending enabled and checks the JSON summary fields.
# @timeout: 180
# @tags: usage, json, network
# @client: iperf3

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-iperf3-json-zerocopy"
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
  local port=$((24000 + RANDOM % 20000))
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

  validator_assert_contains "$tmpdir/client.json" '"end"'
  validator_assert_contains "$tmpdir/client.json" '"bits_per_second"'
  jq -e '(.end | type == "object") and ((.end.sum_sent.bytes // .end.sum.bytes // 0) >= 0)' "$tmpdir/client.json"
}

run_iperf_json -Z -n 32K

#!/usr/bin/env bash
# @testcase: usage-iperf3-json-receiver-tcp-congestion-string
# @title: iperf3 JSON receiver TCP congestion is string
# @description: Validates that the cjson-emitted end.receiver_tcp_congestion is a non-empty string after a TCP loopback transfer.
# @timeout: 180
# @tags: usage, json, iperf3, tcp
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
for _ in $(seq 1 30); do
  if iperf3 -c 127.0.0.1 -p "$port" -J -n 64K >"$tmpdir/client.json" 2>"$tmpdir/client.err"; then
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

validator_assert_contains "$tmpdir/client.json" '"receiver_tcp_congestion"'
jq -e '(.end.receiver_tcp_congestion | type) == "string" and (.end.receiver_tcp_congestion | length) > 0' "$tmpdir/client.json"

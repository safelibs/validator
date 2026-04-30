#!/usr/bin/env bash
# @testcase: usage-iperf3-json-logfile-roundtrip
# @title: iperf3 JSON logfile round-trip
# @description: Runs iperf3 with --logfile so the cjson-serialized JSON report is written to disk, then parses the file with jq to confirm the round-trip is well formed.
# @timeout: 180
# @tags: usage, json, iperf3
# @client: iperf3

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-iperf3-json-logfile-roundtrip"
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

port=$((28000 + RANDOM % 8000))
logfile="$tmpdir/iperf3.log"

iperf3 -s -1 -p "$port" >"$tmpdir/server.log" 2>&1 &
pid=$!

ok=0
for _ in $(seq 1 30); do
  if iperf3 -c 127.0.0.1 -p "$port" -J --logfile "$logfile" -n 16K >"$tmpdir/client.out" 2>"$tmpdir/client.err"; then
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

validator_require_file "$logfile"
validator_assert_contains "$logfile" '"start"'
validator_assert_contains "$logfile" '"end"'
jq -e '(.start | type == "object") and (.end | type == "object") and ((.end.sum_sent.bytes // .end.sum.bytes // 0) > 0)' "$logfile"

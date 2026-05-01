#!/usr/bin/env bash
# @testcase: usage-iperf3-json-half-second-interval-end-monotonic
# @title: iperf3 JSON half-second interval end monotonic
# @description: Runs iperf3 with -i 0.5 -t 2 and verifies the cjson-serialized intervals[].sum.end timestamps are strictly increasing across the report cadence.
# @timeout: 180
# @tags: usage, json, iperf3, intervals
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
  if iperf3 -c 127.0.0.1 -p "$port" -J -t 2 -i 0.5 >"$tmpdir/client.json" 2>"$tmpdir/client.err"; then
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

validator_assert_contains "$tmpdir/client.json" '"intervals"'
jq -e '
  ([.intervals[].sum.end]) as $ends
  | ($ends | length) >= 2
  and ([range(1; $ends | length) | $ends[.] > $ends[. - 1]] | all)
' "$tmpdir/client.json"

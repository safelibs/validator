#!/usr/bin/env bash
# @testcase: usage-iperf3-json-cport-paired-range-33503
# @title: iperf3 JSON paired ports range 33503
# @description: Runs iperf3 with a server port in the 33500-33599 range and a client port of 33503 so cjson must serialize both connected[0].remote_port and connected[0].local_port from a second paired range disjoint from earlier cport pairings.
# @timeout: 180
# @tags: usage, json, iperf3
# @client: iperf3

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-iperf3-json-cport-paired-range-33503"
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

client_port=33503
# Pick a server port in 33500-33599 that is not the pinned client port,
# otherwise the server binds it first and the client cannot reuse it via --cport.
while :; do
  server_port=$((33500 + RANDOM % 100))
  [[ "$server_port" != "$client_port" ]] && break
done

iperf3 -s -1 -p "$server_port" >"$tmpdir/server.log" 2>&1 &
pid=$!

ok=0
for _ in $(seq 1 30); do
  if iperf3 -c 127.0.0.1 -p "$server_port" --cport "$client_port" -J -n 16K \
        >"$tmpdir/client.json" 2>"$tmpdir/client.err"; then
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

validator_assert_contains "$tmpdir/client.json" '"connected"'
jq -e --argjson rp "$server_port" --argjson lp "$client_port" \
  '.start.connected[0].remote_port == $rp and .start.connected[0].local_port == $lp and ($rp >= 33500 and $rp < 33600)' \
  "$tmpdir/client.json"

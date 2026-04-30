#!/usr/bin/env bash
# @testcase: usage-iperf3-json-port-cport-paired
# @title: iperf3 JSON paired remote and local ports
# @description: Runs iperf3 with explicit -p and --cport so the cjson serializer must echo both the remote server port and the local client port in start.connected[0].
# @timeout: 180
# @tags: usage, json, iperf3
# @client: iperf3

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-iperf3-json-port-cport-paired"
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

server_port=$((26000 + RANDOM % 1000))
client_port=$((27000 + RANDOM % 1000))

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

validator_assert_contains "$tmpdir/client.json" '"start"'
jq -e --argjson rp "$server_port" --argjson lp "$client_port" \
  '.start.connected[0].remote_port == $rp and .start.connected[0].local_port == $lp' \
  "$tmpdir/client.json"

#!/usr/bin/env bash
# @testcase: usage-iperf3-json-r16-set-mss-reflected-in-start
# @title: iperf3 -J -M 1200 surfaces sock_bufsize/test_start fields with mss in connecting
# @description: Runs a 1-second loopback TCP transfer with --set-mss 1200 and asserts the cjson-serialised JSON has a well-formed start object including positive sock_bufsize/test_start integers, exercising the MSS-set code path on noble.
# @timeout: 180
# @tags: usage, json, tcp, mss
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
for _ in $(seq 1 20); do
    if iperf3 -c 127.0.0.1 -p "$port" -J -t 1 -M 1200 >"$tmpdir/client.json" 2>"$tmpdir/client.err"; then
        ok=1
        break
    fi
    sleep 0.2
done

wait "$pid"
pid=""

[[ "$ok" == 1 ]] || { sed -n '1,80p' "$tmpdir/client.err" >&2; exit 1; }

jq -e '
  (.start | type == "object")
  and (.start.test_start | type == "object")
  and (.start.sock_bufsize | type == "number")
  and (.start.sock_bufsize >= 0)
  and (.start.tcp_mss_default | type == "number")
  and (.start.tcp_mss_default > 0)
' "$tmpdir/client.json"

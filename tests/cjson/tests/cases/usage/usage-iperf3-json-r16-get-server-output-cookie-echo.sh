#!/usr/bin/env bash
# @testcase: usage-iperf3-json-r16-get-server-output-cookie-echo
# @title: iperf3 -J --get-server-output echoes the same start.cookie under server_output_json
# @description: Runs a 1-second loopback TCP transfer with --get-server-output, asserts the client JSON contains a server_output_json object, and verifies its start.cookie matches the client's own start.cookie string — the cjson-serialised handshake identifier is symmetric across both sides.
# @timeout: 180
# @tags: usage, json, tcp, server-output
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
    if iperf3 -c 127.0.0.1 -p "$port" -J -t 1 --get-server-output >"$tmpdir/client.json" 2>"$tmpdir/client.err"; then
        ok=1
        break
    fi
    sleep 0.2
done

wait "$pid"
pid=""

[[ "$ok" == 1 ]] || { sed -n '1,80p' "$tmpdir/client.err" >&2; exit 1; }

jq -e '
  (.start.cookie | type == "string")
  and (.start.cookie | length > 0)
  and (has("server_output_json"))
  and (.server_output_json.start.cookie | type == "string")
  and (.server_output_json.start.cookie == .start.cookie)
' "$tmpdir/client.json"

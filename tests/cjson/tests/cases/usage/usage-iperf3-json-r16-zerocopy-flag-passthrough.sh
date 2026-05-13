#!/usr/bin/env bash
# @testcase: usage-iperf3-json-r16-zerocopy-flag-passthrough
# @title: iperf3 -J -Z (zerocopy) completes and emits a well-formed end.sum_sent object
# @description: Runs a 1-second loopback TCP transfer with -Z (zerocopy/sendfile send path) and asserts the cjson-serialised top-level JSON is well-formed and end.sum_sent has positive bytes and seconds, confirming the zerocopy flag does not perturb the JSON shape on noble.
# @timeout: 180
# @tags: usage, json, tcp, zerocopy
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
    if iperf3 -c 127.0.0.1 -p "$port" -J -t 1 -Z >"$tmpdir/client.json" 2>"$tmpdir/client.err"; then
        ok=1
        break
    fi
    sleep 0.2
done

wait "$pid"
pid=""

[[ "$ok" == 1 ]] || { sed -n '1,80p' "$tmpdir/client.err" >&2; exit 1; }

jq -e '
  (.end.sum_sent | type == "object")
  and (.end.sum_sent.bytes | type == "number")
  and (.end.sum_sent.bytes > 0)
  and (.end.sum_sent.seconds | type == "number")
  and (.end.sum_sent.seconds > 0)
  and (.end.sum_received.bytes | type == "number")
  and (.end.sum_received.bytes > 0)
' "$tmpdir/client.json"

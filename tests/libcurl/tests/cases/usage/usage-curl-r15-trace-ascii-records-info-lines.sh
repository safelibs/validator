#!/usr/bin/env bash
# @testcase: usage-curl-r15-trace-ascii-records-info-lines
# @title: curl --trace-ascii writes a trace file whose lines start with "==" or direction prefixes
# @description: Runs a curl GET against a loopback server with --trace-ascii <file>, asserts the produced trace file includes "Info:" lines (preceded by "==") for connection events plus directional markers ("=>" or "<=") for the request/response, demonstrating the human-readable trace dump.
# @timeout: 180
# @tags: usage, curl, http, trace
# @client: curl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
pid=""
cleanup() {
    if [[ -n "$pid" ]]; then kill "$pid" 2>/dev/null || true; wait "$pid" 2>/dev/null || true; fi
    rm -rf "$tmpdir"
}
trap cleanup EXIT

mkdir -p "$tmpdir/srv"
printf 'r15 trace-ascii body\n' >"$tmpdir/srv/payload.txt"
port=$((23000 + RANDOM % 19000))
( cd "$tmpdir/srv" && exec python3 -m http.server "$port" >/dev/null 2>&1 ) &
pid=$!
for _ in $(seq 1 60); do
    curl --noproxy '*' -fsS --max-time 2 -o /dev/null "http://127.0.0.1:$port/" 2>/dev/null && break
    sleep 0.1
done

curl --noproxy '*' --max-time 5 \
    --trace-ascii "$tmpdir/trace.log" \
    -o "$tmpdir/got.txt" \
    "http://127.0.0.1:$port/payload.txt" >/dev/null

diff -q "$tmpdir/srv/payload.txt" "$tmpdir/got.txt"
validator_require_file "$tmpdir/trace.log"

# trace-ascii prefixes informational lines with "== Info:" and uses "=>" / "<="
# for outgoing/incoming direction markers.
grep -E '^== Info:' "$tmpdir/trace.log" >/dev/null || {
    printf 'expected "== Info:" line in trace-ascii output\n' >&2
    head -20 "$tmpdir/trace.log" >&2
    exit 1
}
grep -E '^=> Send header' "$tmpdir/trace.log" >/dev/null || {
    printf 'expected "=> Send header" line in trace-ascii output\n' >&2
    head -40 "$tmpdir/trace.log" >&2
    exit 1
}

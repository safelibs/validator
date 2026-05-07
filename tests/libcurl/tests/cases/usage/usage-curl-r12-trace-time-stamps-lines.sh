#!/usr/bin/env bash
# @testcase: usage-curl-r12-trace-time-stamps-lines
# @title: curl --trace-ascii --trace-time prefixes trace lines with HH:MM:SS.microseconds timestamps
# @description: Runs a loopback fetch with --trace-ascii path --trace-time, then asserts at least one line in the trace file begins with the documented timestamp prefix HH:MM:SS.MICROSECONDS produced by --trace-time.
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
printf 'r12 trace-time body\n' >"$tmpdir/srv/index.html"
port=$((23000 + RANDOM % 19000))
( cd "$tmpdir/srv" && python3 -m http.server "$port" >/dev/null 2>&1 ) &
pid=$!
for _ in $(seq 1 60); do
    curl --noproxy '*' -fsS --max-time 2 -o /dev/null "http://127.0.0.1:$port/" 2>/dev/null && break
    sleep 0.1
done

curl --noproxy '*' -fsS --max-time 5 \
    --trace-ascii "$tmpdir/trace.log" --trace-time \
    -o /dev/null "http://127.0.0.1:$port/index.html"

validator_require_file "$tmpdir/trace.log"
# At least one line must start with HH:MM:SS.uuuuuu (six microsecond digits).
grep -E '^[0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]{6}' "$tmpdir/trace.log" >/dev/null || {
    printf 'expected timestamp-prefixed trace line\n' >&2
    head -n 5 "$tmpdir/trace.log" >&2
    exit 1
}

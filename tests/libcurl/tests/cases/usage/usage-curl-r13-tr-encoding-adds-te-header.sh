#!/usr/bin/env bash
# @testcase: usage-curl-r13-tr-encoding-adds-te-header
# @title: curl --tr-encoding emits the documented TE: gzip request header
# @description: Issues a verbose curl request against a loopback server with --tr-encoding, captures the verbose stderr trace, and asserts the request line block contains a literal "TE: gzip" line, confirming curl asks for compressed transfer-encoding.
# @timeout: 180
# @tags: usage, curl, http, transfer-encoding
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
printf 'r13 tr-encoding body\n' >"$tmpdir/srv/payload.txt"
port=$((23000 + RANDOM % 19000))
( cd "$tmpdir/srv" && python3 -m http.server "$port" >/dev/null 2>&1 ) &
pid=$!
for _ in $(seq 1 60); do
    curl --noproxy '*' -fsS --max-time 2 -o /dev/null "http://127.0.0.1:$port/" 2>/dev/null && break
    sleep 0.1
done

curl --noproxy '*' -v --max-time 5 --tr-encoding \
    -o /dev/null "http://127.0.0.1:$port/payload.txt" >"$tmpdir/stdout.log" 2>"$tmpdir/stderr.log"

# Verbose request lines are prefixed with '> '. Look for the exact TE: gzip header.
grep -E '^> TE: gzip' "$tmpdir/stderr.log" >/dev/null || {
    printf 'expected "TE: gzip" request header from --tr-encoding\n' >&2
    cat "$tmpdir/stderr.log" >&2
    exit 1
}

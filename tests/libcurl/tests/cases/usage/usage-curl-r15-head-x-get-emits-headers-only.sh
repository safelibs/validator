#!/usr/bin/env bash
# @testcase: usage-curl-r15-head-x-get-emits-headers-only
# @title: curl -I -X GET prints response headers without the body even when the method is overridden to GET
# @description: Runs curl -I -X GET against a loopback HTTP server, captures stdout, and asserts the captured stream contains the HTTP/1.0 200 status line plus the Content-Length header but does NOT contain the served response body. Pins curl's "headers-only" mode under -I when the method is overridden to GET.
# @timeout: 180
# @tags: usage, curl, http, head
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
printf 'r15-head-x-get-unique-marker\n' >"$tmpdir/srv/payload.txt"
port=$((23000 + RANDOM % 19000))
( cd "$tmpdir/srv" && exec python3 -m http.server "$port" >/dev/null 2>&1 ) &
pid=$!
for _ in $(seq 1 60); do
    curl --noproxy '*' -fsS --max-time 2 -o /dev/null "http://127.0.0.1:$port/" 2>/dev/null && break
    sleep 0.1
done

curl --noproxy '*' -sS --max-time 5 \
    -I -X GET \
    "http://127.0.0.1:$port/payload.txt" >"$tmpdir/headers.out"

# Must contain the 200 status line and Content-Length header.
grep -E '^HTTP/1\.[01] 200' "$tmpdir/headers.out" >/dev/null || {
    printf 'expected HTTP/1.x 200 status line in -I -X GET output\n' >&2
    cat "$tmpdir/headers.out" >&2
    exit 1
}
grep -E '^Content-[Ll]ength:' "$tmpdir/headers.out" >/dev/null || {
    printf 'expected Content-Length header in -I -X GET output\n' >&2
    cat "$tmpdir/headers.out" >&2
    exit 1
}

# Body marker must NOT appear in headers-only output.
if grep -F 'r15-head-x-get-unique-marker' "$tmpdir/headers.out" >/dev/null; then
    printf 'unexpected body content in -I -X GET output\n' >&2
    cat "$tmpdir/headers.out" >&2
    exit 1
fi

#!/usr/bin/env bash
# @testcase: usage-curl-r15-write-out-size-header
# @title: curl --write-out '%{size_header}' reports a positive byte count for the received response headers
# @description: Issues a curl GET against a loopback HTTP server with --write-out '%{size_header}\n' and asserts the captured value is a positive integer, demonstrating that curl exposes the total received-header byte count via the size_header writeout token.
# @timeout: 180
# @tags: usage, curl, http, write-out, size-header
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
printf 'r15 size_header body\n' >"$tmpdir/srv/payload.txt"
port=$((23000 + RANDOM % 19000))
( cd "$tmpdir/srv" && exec python3 -m http.server "$port" >/dev/null 2>&1 ) &
pid=$!
for _ in $(seq 1 60); do
    curl --noproxy '*' -fsS --max-time 2 -o /dev/null "http://127.0.0.1:$port/" 2>/dev/null && break
    sleep 0.1
done

n=$(curl --noproxy '*' -fsS --max-time 5 \
    -o /dev/null -w '%{size_header}' \
    "http://127.0.0.1:$port/payload.txt")
[[ "$n" =~ ^[0-9]+$ ]] || {
    printf 'expected integer size_header, got %q\n' "$n" >&2
    exit 1
}
[[ "$n" -gt 0 ]] || {
    printf 'expected size_header > 0, got %d\n' "$n" >&2
    exit 1
}

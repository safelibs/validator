#!/usr/bin/env bash
# @testcase: usage-curl-r12-ignore-content-length-flag
# @title: curl --ignore-content-length still receives the full body when server reports the length
# @description: Fetches a loopback file with --ignore-content-length and verifies curl reports HTTP 200 and the captured bytes match the source byte-for-byte, demonstrating that ignoring the Content-Length header does not truncate the response on a normal connection.
# @timeout: 180
# @tags: usage, curl, http, ignore-content-length
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
printf 'r12 ignore-cl body row\n%.0s' {1..32} >"$tmpdir/srv/payload.bin"
port=$((23000 + RANDOM % 19000))
( cd "$tmpdir/srv" && python3 -m http.server "$port" >/dev/null 2>&1 ) &
pid=$!
for _ in $(seq 1 60); do
    curl --noproxy '*' -fsS --max-time 2 -o /dev/null "http://127.0.0.1:$port/payload.bin" 2>/dev/null && break
    sleep 0.1
done

code=$(curl --noproxy '*' -sS --max-time 10 --ignore-content-length \
            -o "$tmpdir/got.bin" -w '%{response_code}' \
            "http://127.0.0.1:$port/payload.bin")
[[ "$code" == "200" ]] || {
    printf 'expected 200, got %q\n' "$code" >&2
    exit 1
}
cmp "$tmpdir/got.bin" "$tmpdir/srv/payload.bin"

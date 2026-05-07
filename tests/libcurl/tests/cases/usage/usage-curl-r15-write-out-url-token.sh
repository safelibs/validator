#!/usr/bin/env bash
# @testcase: usage-curl-r15-write-out-url-token
# @title: curl --write-out '%{url}' echoes the request URL exactly as supplied on the command line
# @description: Runs a curl GET against a loopback HTTP server with --write-out 'url=%{url}', captures stdout, and asserts the writeout line equals "url=" followed by the request URL passed to curl. Pins the lossless echo of the input URL by the %{url} token.
# @timeout: 180
# @tags: usage, curl, http, write-out, url
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
printf 'r15 url-token body\n' >"$tmpdir/srv/payload.txt"
port=$((23000 + RANDOM % 19000))
( cd "$tmpdir/srv" && exec python3 -m http.server "$port" >/dev/null 2>&1 ) &
pid=$!
for _ in $(seq 1 60); do
    curl --noproxy '*' -fsS --max-time 2 -o /dev/null "http://127.0.0.1:$port/" 2>/dev/null && break
    sleep 0.1
done

url="http://127.0.0.1:$port/payload.txt"
got=$(curl --noproxy '*' -fsS --max-time 5 \
    -o /dev/null -w 'url=%{url}' "$url")
[[ "$got" == "url=$url" ]] || {
    printf 'expected url=%q, got %q\n' "$url" "$got" >&2
    exit 1
}

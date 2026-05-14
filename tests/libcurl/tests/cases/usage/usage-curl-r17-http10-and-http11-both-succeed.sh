#!/usr/bin/env bash
# @testcase: usage-curl-r17-http10-and-http11-both-succeed
# @title: curl --http1.0 and --http1.1 each fetch a loopback resource successfully
# @description: Stands up a python http.server serving a static file, asserts the server is reachable, then issues two curl requests — one with --http1.0 and one with --http1.1 — and confirms both responses match the file's content byte-for-byte.
# @timeout: 90
# @tags: usage, curl, http-version
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

mkdir -p "$tmpdir/wwwroot"
printf 'r17-http-version-body\n' >"$tmpdir/wwwroot/file.txt"

port=$((24600 + RANDOM % 18000))
python3 -m http.server "$port" --bind 127.0.0.1 --directory "$tmpdir/wwwroot" >/dev/null 2>&1 &
pid=$!
ready=0
for _ in $(seq 1 60); do
    if curl --noproxy '*' -fsS --max-time 2 -o /dev/null "http://127.0.0.1:$port/file.txt" 2>/dev/null; then
        ready=1
        break
    fi
    sleep 0.1
done
[[ "$ready" -eq 1 ]] || { printf 'server never became ready\n' >&2; exit 1; }

curl --noproxy '*' -fsS --max-time 5 --http1.0 \
    "http://127.0.0.1:$port/file.txt" -o "$tmpdir/h10.txt"
curl --noproxy '*' -fsS --max-time 5 --http1.1 \
    "http://127.0.0.1:$port/file.txt" -o "$tmpdir/h11.txt"

diff -q "$tmpdir/wwwroot/file.txt" "$tmpdir/h10.txt"
diff -q "$tmpdir/wwwroot/file.txt" "$tmpdir/h11.txt"

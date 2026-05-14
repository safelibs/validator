#!/usr/bin/env bash
# @testcase: usage-curl-r17-insecure-flag-noop-on-http
# @title: curl --insecure is accepted on an http URL and fetches the resource normally
# @description: Stands up a python http.server serving a small file, then issues curl with --insecure against the plain http URL and asserts the response body matches the served file — locking in that --insecure is a no-op on non-TLS schemes rather than rejected.
# @timeout: 90
# @tags: usage, curl, insecure
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
printf 'r17-insecure-http-body\n' >"$tmpdir/wwwroot/file.txt"

port=$((24900 + RANDOM % 18000))
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

curl --noproxy '*' -fsS --insecure --max-time 5 \
    "http://127.0.0.1:$port/file.txt" -o "$tmpdir/got.txt"

diff -q "$tmpdir/wwwroot/file.txt" "$tmpdir/got.txt"

#!/usr/bin/env bash
# @testcase: usage-curl-r14-xattr-records-origin-url
# @title: curl --xattr writes user.xdg.origin.url and user.mime_type onto the saved file
# @description: Fetches a file from a loopback HTTP server with curl --xattr, then enumerates the saved file's user-namespace extended attributes via os.listxattr in python and asserts user.xdg.origin.url is present and equals the request URL, and user.mime_type is present.
# @timeout: 180
# @tags: usage, curl, http, xattr
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
printf 'r14 xattr payload\n' >"$tmpdir/srv/marker.txt"
port=$((23000 + RANDOM % 19000))
( cd "$tmpdir/srv" && exec python3 -m http.server "$port" >/dev/null 2>&1 ) &
pid=$!
for _ in $(seq 1 60); do
    curl --noproxy '*' -fsS --max-time 2 -o /dev/null "http://127.0.0.1:$port/" 2>/dev/null && break
    sleep 0.1
done

url="http://127.0.0.1:$port/marker.txt"
curl --noproxy '*' -fsS --max-time 5 --xattr \
    -o "$tmpdir/got.txt" "$url"
validator_require_file "$tmpdir/got.txt"

python3 - "$tmpdir/got.txt" "$url" <<'PY' >"$tmpdir/xattr.out"
import os, sys
path, expected_url = sys.argv[1], sys.argv[2]
attrs = sorted(os.listxattr(path))
print('attrs=' + ','.join(attrs))
if 'user.xdg.origin.url' in attrs:
    print('origin_url=' + os.getxattr(path, 'user.xdg.origin.url').decode())
if 'user.mime_type' in attrs:
    print('mime_type=' + os.getxattr(path, 'user.mime_type').decode())
print('expected_url=' + expected_url)
PY

validator_assert_contains "$tmpdir/xattr.out" 'user.xdg.origin.url'
validator_assert_contains "$tmpdir/xattr.out" 'user.mime_type'
expected_url_line=$(grep '^origin_url=' "$tmpdir/xattr.out" | head -n1)
[[ "$expected_url_line" == "origin_url=$url" ]] || {
    printf 'origin url mismatch: %q vs origin_url=%q\n' "$expected_url_line" "$url" >&2
    cat "$tmpdir/xattr.out" >&2
    exit 1
}

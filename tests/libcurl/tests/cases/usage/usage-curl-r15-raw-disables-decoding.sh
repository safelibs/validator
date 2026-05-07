#!/usr/bin/env bash
# @testcase: usage-curl-r15-raw-disables-decoding
# @title: curl --raw passes the response body through without internal decoding and reports the raw byte count
# @description: Fetches a static file from a loopback HTTP server with curl --raw, captures the body to a file plus '%{size_download}' from --write-out, and asserts both the saved file size and the writeout-reported byte count equal the on-disk source file size, demonstrating that --raw disables internal transfer-encoding decoding.
# @timeout: 180
# @tags: usage, curl, http, raw
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
python3 -c 'import sys
sys.stdout.buffer.write(b"r15 raw byte body\n" * 64)' >"$tmpdir/srv/payload.bin"
expected_size=$(stat -c '%s' "$tmpdir/srv/payload.bin")
port=$((23000 + RANDOM % 19000))
( cd "$tmpdir/srv" && exec python3 -m http.server "$port" >/dev/null 2>&1 ) &
pid=$!
for _ in $(seq 1 60); do
    curl --noproxy '*' -fsS --max-time 2 -o /dev/null "http://127.0.0.1:$port/" 2>/dev/null && break
    sleep 0.1
done

reported=$(curl --noproxy '*' -fsS --max-time 5 --raw \
    -o "$tmpdir/got.bin" -w '%{size_download}' \
    "http://127.0.0.1:$port/payload.bin")

[[ "$reported" == "$expected_size" ]] || {
    printf 'expected size_download=%s, got %q\n' "$expected_size" "$reported" >&2
    exit 1
}
got_size=$(stat -c '%s' "$tmpdir/got.bin")
[[ "$got_size" == "$expected_size" ]] || {
    printf 'expected got.bin size %s, got %s\n' "$expected_size" "$got_size" >&2
    exit 1
}
diff -q "$tmpdir/srv/payload.bin" "$tmpdir/got.bin"

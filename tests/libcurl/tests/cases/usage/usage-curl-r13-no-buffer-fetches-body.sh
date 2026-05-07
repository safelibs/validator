#!/usr/bin/env bash
# @testcase: usage-curl-r13-no-buffer-fetches-body
# @title: curl --no-buffer (-N) writes the response body to the output file unchanged
# @description: Fetches a small file from a loopback HTTP server with curl --no-buffer (-N) and asserts the on-disk output matches the source byte-for-byte and that --no-buffer does not corrupt or truncate the body.
# @timeout: 180
# @tags: usage, curl, http, buffer
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
sys.stdout.buffer.write(b"r13 no-buffer payload row\n" * 64)' >"$tmpdir/srv/payload.txt"
port=$((23000 + RANDOM % 19000))
( cd "$tmpdir/srv" && python3 -m http.server "$port" >/dev/null 2>&1 ) &
pid=$!
for _ in $(seq 1 60); do
    curl --noproxy '*' -fsS --max-time 2 -o /dev/null "http://127.0.0.1:$port/" 2>/dev/null && break
    sleep 0.1
done

curl --noproxy '*' -fsS --max-time 5 --no-buffer \
    -o "$tmpdir/got.txt" "http://127.0.0.1:$port/payload.txt"
diff -q "$tmpdir/srv/payload.txt" "$tmpdir/got.txt"

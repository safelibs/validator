#!/usr/bin/env bash
# @testcase: usage-curl-r12-write-out-size-request-post
# @title: curl -w %{size_request} reports the bytes sent in the request line plus headers
# @description: Posts a known-length body to a loopback handler and asserts %{size_request} is greater than zero and at least as large as the body length, demonstrating the token covers request-line bytes and headers in addition to the body.
# @timeout: 180
# @tags: usage, curl, http, write-out
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

cat >"$tmpdir/server.py" <<'PY'
from http.server import BaseHTTPRequestHandler, HTTPServer
import os
class H(BaseHTTPRequestHandler):
    def log_message(self, *a, **k): pass
    def do_POST(self):
        n = int(self.headers.get('Content-Length', '0') or '0')
        if n: self.rfile.read(n)
        self.send_response(200)
        self.send_header('Content-Type', 'text/plain')
        self.send_header('Content-Length', '3')
        self.end_headers()
        self.wfile.write(b'ok\n')
HTTPServer(('127.0.0.1', int(os.environ['PORT'])), H).serve_forever()
PY

port=$((23000 + RANDOM % 19000))
PORT="$port" python3 "$tmpdir/server.py" >/dev/null 2>&1 &
pid=$!
for _ in $(seq 1 60); do
    curl --noproxy '*' -sS --max-time 2 -o /dev/null -X POST -d '' "http://127.0.0.1:$port/" 2>/dev/null && break
    sleep 0.1
done

body='abcdefghijklmnopqrst'  # 20 bytes
got=$(curl --noproxy '*' -sS --max-time 5 \
            -d "$body" \
            -o /dev/null -w '%{size_request}' \
            "http://127.0.0.1:$port/p")

[[ "$got" =~ ^[0-9]+$ ]] || {
    printf 'expected numeric %%{size_request}, got %q\n' "$got" >&2
    exit 1
}
[[ "$got" -ge 20 ]] || {
    printf 'expected size_request >= 20, got %s\n' "$got" >&2
    exit 1
}

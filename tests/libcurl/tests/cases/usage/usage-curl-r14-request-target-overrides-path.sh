#!/usr/bin/env bash
# @testcase: usage-curl-r14-request-target-overrides-path
# @title: curl --request-target rewrites the HTTP request line path independently of the URL
# @description: Issues curl with a URL whose path is /placeholder but with --request-target /actual.txt, runs against a python handler that echoes back the request-line path, and asserts the recorded request path is /actual.txt rather than /placeholder.
# @timeout: 180
# @tags: usage, curl, http, request-target
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
    def do_GET(self):
        body = ('path=' + self.path + '\n').encode()
        self.send_response(200)
        self.send_header('Content-Type', 'text/plain')
        self.send_header('Content-Length', str(len(body)))
        self.end_headers()
        self.wfile.write(body)
HTTPServer(('127.0.0.1', int(os.environ['PORT'])), H).serve_forever()
PY

port=$((23000 + RANDOM % 19000))
PORT="$port" python3 "$tmpdir/server.py" >/dev/null 2>&1 &
pid=$!
for _ in $(seq 1 60); do
    curl --noproxy '*' -fsS --max-time 2 -o /dev/null "http://127.0.0.1:$port/" 2>/dev/null && break
    sleep 0.1
done

curl --noproxy '*' -fsS --max-time 5 \
    --request-target /actual.txt \
    -o "$tmpdir/echo.out" "http://127.0.0.1:$port/placeholder"

validator_assert_contains "$tmpdir/echo.out" 'path=/actual.txt'
if grep -q '^path=/placeholder' "$tmpdir/echo.out"; then
    printf 'expected /actual.txt to override /placeholder, got:\n' >&2
    cat "$tmpdir/echo.out" >&2
    exit 1
fi

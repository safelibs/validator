#!/usr/bin/env bash
# @testcase: usage-curl-r14-header-from-file-at-prefix
# @title: curl -H @file reads multiple custom headers from a newline-delimited file
# @description: Writes a header file with two custom request headers, runs curl with -H @<file> against a python BaseHTTPRequestHandler that echoes back every received header, and asserts both custom header names and values appear verbatim in the echoed response, demonstrating the @file ingestion path for -H.
# @timeout: 180
# @tags: usage, curl, http, headers, file
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
        # Echo every received header on its own line.
        rows = ['%s: %s' % (k, v) for k, v in self.headers.items()]
        body = ('\n'.join(rows) + '\n').encode()
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

cat >"$tmpdir/headers.txt" <<'HDR'
X-Validator-R14: from-file
X-Marker: r14-headerfile
HDR

curl --noproxy '*' -fsS --max-time 5 \
    -H @"$tmpdir/headers.txt" \
    -o "$tmpdir/echo.out" "http://127.0.0.1:$port/echo"

validator_assert_contains "$tmpdir/echo.out" 'X-Validator-R14: from-file'
validator_assert_contains "$tmpdir/echo.out" 'X-Marker: r14-headerfile'

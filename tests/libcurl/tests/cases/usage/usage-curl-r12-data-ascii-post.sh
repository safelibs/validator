#!/usr/bin/env bash
# @testcase: usage-curl-r12-data-ascii-post
# @title: curl --data-ascii posts the literal payload with a default form content type
# @description: Posts a literal payload via curl --data-ascii to a loopback handler that echoes the request body and Content-Type header, asserts the recorded body matches the supplied bytes and the default Content-Type is application/x-www-form-urlencoded.
# @timeout: 180
# @tags: usage, curl, http, post
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
        body = self.rfile.read(n) if n else b''
        ct = self.headers.get('Content-Type', '')
        out = ('ct=' + ct + '\nbody=' + body.decode('utf-8', errors='replace') + '\n').encode()
        self.send_response(200)
        self.send_header('Content-Type', 'text/plain')
        self.send_header('Content-Length', str(len(out)))
        self.end_headers()
        self.wfile.write(out)
HTTPServer(('127.0.0.1', int(os.environ['PORT'])), H).serve_forever()
PY

port=$((23000 + RANDOM % 19000))
PORT="$port" python3 "$tmpdir/server.py" >/dev/null 2>&1 &
pid=$!
for _ in $(seq 1 60); do
    curl --noproxy '*' -sS --max-time 2 -o /dev/null -X POST -d '' "http://127.0.0.1:$port/" 2>/dev/null && break
    sleep 0.1
done

curl --noproxy '*' -fsS --max-time 5 \
    --data-ascii 'r12-data-ascii-marker=hello' \
    -o "$tmpdir/out" "http://127.0.0.1:$port/echo"

validator_assert_contains "$tmpdir/out" 'ct=application/x-www-form-urlencoded'
validator_assert_contains "$tmpdir/out" 'body=r12-data-ascii-marker=hello'

#!/usr/bin/env bash
# @testcase: usage-curl-r12-post301-keeps-method
# @title: curl --post301 -L preserves POST when following a 301 redirect
# @description: Hosts a loopback handler that returns 301 Location -> /target and reports the request method on /target, posts a body via curl -L --post301, and asserts the followed request was still POST (not converted to GET).
# @timeout: 180
# @tags: usage, curl, http, redirect, post
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
    def _redirect(self):
        self.send_response(301)
        self.send_header('Location', '/target')
        self.send_header('Content-Length', '0')
        self.end_headers()
    def _report(self):
        body = ('method=' + self.command + '\n').encode()
        self.send_response(200)
        self.send_header('Content-Type', 'text/plain')
        self.send_header('Content-Length', str(len(body)))
        self.end_headers()
        self.wfile.write(body)
    def do_GET(self):
        if self.path == '/start': self._redirect()
        else: self._report()
    def do_POST(self):
        # Drain any body so the connection is reusable.
        n = int(self.headers.get('Content-Length', '0') or '0')
        if n: self.rfile.read(n)
        if self.path == '/start': self._redirect()
        else: self._report()
HTTPServer(('127.0.0.1', int(os.environ['PORT'])), H).serve_forever()
PY

port=$((23000 + RANDOM % 19000))
PORT="$port" python3 "$tmpdir/server.py" >/dev/null 2>&1 &
pid=$!
for _ in $(seq 1 60); do
    curl --noproxy '*' -fsS --max-time 2 -o /dev/null "http://127.0.0.1:$port/target" 2>/dev/null && break
    sleep 0.1
done

curl --noproxy '*' -fsS --max-time 5 -L --post301 \
    -d 'k=v' -o "$tmpdir/out" "http://127.0.0.1:$port/start"
validator_assert_contains "$tmpdir/out" 'method=POST'

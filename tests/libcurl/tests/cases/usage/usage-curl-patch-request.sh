#!/usr/bin/env bash
# @testcase: usage-curl-patch-request
# @title: curl PATCH request
# @description: Sends a PATCH request with curl and verifies the echoed method and body.
# @timeout: 180
# @tags: usage, curl, http
# @client: curl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-curl-patch-request"
tmpdir=$(mktemp -d)
pid=""
cleanup() {
  if [[ -n "$pid" ]]; then
    kill "$pid" 2>/dev/null || true
    wait "$pid" 2>/dev/null || true
  fi
  rm -rf "$tmpdir"
}
trap cleanup EXIT

cat >"$tmpdir/server.py" <<'PYCASE'
import http.server
import os
from pathlib import Path

state_dir = Path(os.environ['STATE_DIR'])
state_dir.mkdir(parents=True, exist_ok=True)

class Handler(http.server.BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        pass

    def _body(self):
        length = int(self.headers.get('Content-Length', '0'))
        return self.rfile.read(length)

    def _send(self, code=200, body=b'', content_type='text/plain', headers=None):
        self.send_response(code)
        self.send_header('Content-Type', content_type)
        self.send_header('Content-Length', str(len(body)))
        if headers:
            for key, value in headers.items():
                self.send_header(key, value)
        self.end_headers()
        if body and self.command != 'HEAD':
            self.wfile.write(body)

    def do_GET(self):
        if self.path == '/retry':
            counter = state_dir / 'retry-count'
            count = int(counter.read_text() or '0') if counter.exists() else 0
            count += 1
            counter.write_text(str(count))
            if count == 1:
                self._send(503, b'try again')
            else:
                self._send(200, b'retry ok')
        elif self.path == '/cookie-check':
            self._send(200, self.headers.get('Cookie', '').encode('utf-8'))
        elif self.path == '/type':
            self._send(200, b'typed payload', content_type='application/demo')
        elif self.path == '/proto':
            self._send(200, self.request_version.encode('utf-8'))
        elif self.path == '/loopback':
            self._send(200, b'loopback ok')
        else:
            self._send(200, self.path.encode('utf-8'))

    def do_POST(self):
        body = self._body()
        if self.path == '/json':
            payload = (self.headers.get('Content-Type', '') + '\n').encode('utf-8') + body
            self._send(200, payload)
        elif self.path == '/form':
            self._send(200, body)
        else:
            self._send(200, body)

    def do_PATCH(self):
        self._send(200, b'PATCH\n' + self._body())

    def do_OPTIONS(self):
        self._send(204, b'', headers={'Allow': 'GET, POST, PATCH, OPTIONS, TRACE'})

    def do_TRACE(self):
        body = f'{self.command} {self.path} {self.request_version}'.encode('utf-8')
        self._send(200, body)

http.server.ThreadingHTTPServer(('127.0.0.1', int(os.environ['PORT'])), Handler).serve_forever()
PYCASE

port=$((29000 + RANDOM % 10000))
STATE_DIR="$tmpdir/state" PORT="$port" python3 "$tmpdir/server.py" >"$tmpdir/server.log" 2>&1 &
pid=$!
for _ in $(seq 1 50); do
  if curl -fsS "http://127.0.0.1:$port/loopback" >"$tmpdir/probe" 2>/dev/null; then
    break
  fi
  sleep 0.1
done

curl -fsS -X PATCH --data 'patch-body' "http://127.0.0.1:$port/patch" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'PATCH'
validator_assert_contains "$tmpdir/out" 'patch-body'

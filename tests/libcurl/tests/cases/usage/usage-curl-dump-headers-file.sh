#!/usr/bin/env bash
# @testcase: usage-curl-dump-headers-file
# @title: curl dump headers file
# @description: Saves HTTP response headers to a file with curl and verifies the content-type header is recorded.
# @timeout: 180
# @tags: usage, curl, http
# @client: curl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-curl-dump-headers-file"
tmpdir=$(mktemp -d)
trap 'jobs -pr | xargs -r kill 2>/dev/null || true; rm -rf "$tmpdir"' EXIT

start_custom_server() {
  local port=$1
  cat >"$tmpdir/server.py" <<'PY'
from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import parse_qs, urlparse
import sys

class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        return

    def _send(self, status, body=b"", *, headers=None):
        self.send_response(status)
        for key, value in (headers or {}).items():
            self.send_header(key, value)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        if self.command != "HEAD":
            self.wfile.write(body)

    def do_HEAD(self):
        self.do_GET()

    def do_GET(self):
        parsed = urlparse(self.path)
        if parsed.path == "/redirect":
            self._send(302, headers={"Location": "/plain.txt"})
            return
        if parsed.path == "/plain.txt":
            self._send(200, b"custom server body\n", headers={"Content-Type": "text/plain"})
            return
        if parsed.path == "/headers":
            body = (
                f"referer={self.headers.get('Referer', '')}\n"
                f"authorization={self.headers.get('Authorization', '')}\n"
            ).encode()
            self._send(200, body, headers={"Content-Type": "text/plain"})
            return
        if parsed.path == "/set-cookie":
            self._send(200, b"cookie-set\n", headers={"Content-Type": "text/plain", "Set-Cookie": "validator=present"})
            return
        if parsed.path == "/echo-cookie":
            body = f"cookie={self.headers.get('Cookie', '')}\n".encode()
            self._send(200, body, headers={"Content-Type": "text/plain"})
            return
        if parsed.path == "/auth":
            body = f"authorization={self.headers.get('Authorization', '')}\n".encode()
            self._send(200, body, headers={"Content-Type": "text/plain"})
            return
        if parsed.path == "/query":
            body = parsed.query.encode()
            self._send(200, body, headers={"Content-Type": "text/plain"})
            return
        if parsed.path == "/etag":
            etag = '"validator-etag"'
            if self.headers.get("If-None-Match") == etag:
                self._send(304, headers={"ETag": etag})
                return
            self._send(200, b"etag-body\n", headers={"Content-Type": "text/plain", "ETag": etag})
            return
        self._send(404, b"missing\n", headers={"Content-Type": "text/plain"})

    def do_POST(self):
        size = int(self.headers.get("Content-Length", "0"))
        body = self.rfile.read(size)
        response = b"content-type=" + self.headers.get("Content-Type", "").encode() + b"\nbody=" + body
        self._send(200, response, headers={"Content-Type": "text/plain"})

HTTPServer(("127.0.0.1", int(sys.argv[1])), Handler).serve_forever()
PY
  python3 "$tmpdir/server.py" "$port" >"$tmpdir/http.log" 2>&1 &
  for _ in $(seq 1 40); do
    if curl -fsS "http://127.0.0.1:$port/plain.txt" >/dev/null 2>&1; then
      return 0
    fi
    sleep 0.25
  done
  cat "$tmpdir/http.log" >&2
  return 1
}

port=18102
start_custom_server "$port"
curl -fsS -D "$tmpdir/headers.txt" -o /dev/null "http://127.0.0.1:$port/plain.txt"
validator_assert_contains "$tmpdir/headers.txt" 'Content-Type: text/plain'

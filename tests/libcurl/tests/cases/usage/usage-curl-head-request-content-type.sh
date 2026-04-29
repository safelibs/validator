#!/usr/bin/env bash
# @testcase: usage-curl-head-request-content-type
# @title: curl HEAD request content type
# @description: Sends an HTTP HEAD request with curl and verifies the content type response header is returned.
# @timeout: 180
# @tags: usage, http, cli
# @client: curl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-curl-head-request-content-type"
tmpdir=$(mktemp -d)
trap 'jobs -pr | xargs -r kill 2>/dev/null || true; rm -rf "$tmpdir"' EXIT

start_server() {
  local port=$1
  cat >"$tmpdir/server.py" <<'PY'
from http.server import BaseHTTPRequestHandler, HTTPServer
import base64
import gzip
import sys

class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        return
    def _send(self, body, status=200, headers=None, head_only=False):
        self.send_response(status)
        for key, value in (headers or {}).items():
            self.send_header(key, value)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        if not head_only:
            self.wfile.write(body)
    def _response(self):
        if self.path.startswith("/query"):
            return self.path.encode(), 200, {}
        if self.path == "/auth":
            expected = "Basic " + base64.b64encode(b"user:pass").decode()
            body = b"auth ok\n" if self.headers.get("Authorization") == expected else b"auth missing\n"
            return body, 200, {}
        if self.path == "/set-cookie":
            return b"cookie set\n", 200, {"Set-Cookie": "validator=present; Path=/"}
        if self.path == "/check-cookie":
            return (self.headers.get("Cookie", "missing") + "\n").encode(), 200, {}
        if self.path == "/range":
            body = b"0123456789"
            if self.headers.get("Range") == "bytes=2-5":
                return body[2:6], 206, {"Content-Range": "bytes 2-5/10"}
            return body, 200, {}
        if self.path == "/gzip":
            return gzip.compress(b"compressed body\n"), 200, {"Content-Encoding": "gzip"}
        if self.path == "/files/plain.txt":
            return b"remote-name payload\n", 200, {"Content-Type": "text/plain"}
        if self.path == "/type":
            return b"typed body\n", 200, {"Content-Type": "text/plain"}
        if self.path == "/redirect":
            return b"", 302, {"Location": "/type"}
        if self.path == "/user-agent":
            return (self.headers.get("User-Agent", "missing") + "\n").encode(), 200, {}
        if self.path == "/custom-header":
            return (self.headers.get("X-Validator", "missing") + "\n").encode(), 200, {}
        return b"missing\n", 404, {}
    def do_GET(self):
        body, status, headers = self._response()
        self._send(body, status, headers)
    def do_HEAD(self):
        body, status, headers = self._response()
        self._send(body, status, headers, head_only=True)
    def do_PUT(self):
        size = int(self.headers.get("Content-Length", "0"))
        self._send(b"put:" + self.rfile.read(size))
    def do_POST(self):
        size = int(self.headers.get("Content-Length", "0"))
        body = self.rfile.read(size)
        ctype = self.headers.get("Content-Type", "")
        if self.path == "/json":
            self._send((ctype + "\n").encode() + body)
        elif self.path == "/form-urlencoded":
            self._send((ctype + "\n").encode() + body)
        elif self.path == "/echo":
            self._send(body)
        else:
            self._send(body)

HTTPServer(("127.0.0.1", int(sys.argv[1])), Handler).serve_forever()
PY
  python3 "$tmpdir/server.py" "$port" >"$tmpdir/server.log" 2>&1 &
  for _ in $(seq 1 40); do
    curl -fsS "http://127.0.0.1:$port/type" >/dev/null 2>&1 && return 0
    sleep 0.2
  done
  cat "$tmpdir/server.log" >&2
  return 1
}

port=$((18000 + RANDOM % 20000))
start_server "$port"
base="http://127.0.0.1:$port"

curl -fsSI "$base/type" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'Content-Type: text/plain'

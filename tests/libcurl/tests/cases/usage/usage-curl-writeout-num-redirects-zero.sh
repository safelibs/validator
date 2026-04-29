#!/usr/bin/env bash
# @testcase: usage-curl-writeout-num-redirects-zero
# @title: curl writeout zero redirects
# @description: Verifies the num_redirects writeout reports zero when the server response does not redirect.
# @timeout: 180
# @tags: usage, curl, http
# @client: curl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-curl-writeout-num-redirects-zero"
tmpdir=$(mktemp -d)
trap 'jobs -pr | xargs -r kill 2>/dev/null || true; rm -rf "$tmpdir"' EXIT

start_custom_server() {
  local port=$1
  cat >"$tmpdir/server.py" <<'PY'
from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import urlparse
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
        if parsed.path == "/text":
            self._send(200, b"text-body\n", headers={"Content-Type": "text/plain", "X-Validator": "tenth-batch"})
            return
        if parsed.path == "/slow":
            self._send(200, b"slow-body\n", headers={"Content-Type": "text/plain"})
            return
        if parsed.path == "/range":
            body = b"0123456789abcdef"
            req_range = self.headers.get("Range", "")
            if req_range.startswith("bytes="):
                spec = req_range.split("=", 1)[1]
                start_s, _, end_s = spec.partition("-")
                start = int(start_s)
                end = int(end_s) if end_s else len(body) - 1
                chunk = body[start:end + 1]
                self._send(206, chunk, headers={"Content-Type": "application/octet-stream", "Content-Range": f"bytes {start}-{end}/{len(body)}"})
                return
            self._send(200, body, headers={"Content-Type": "application/octet-stream"})
            return
        if parsed.path == "/bigheader":
            self._send(200, b"hdrbody\n", headers={"Content-Type": "text/plain", "X-Validator-Tenth": "alpha-beta"})
            return
        if parsed.path == "/host-echo":
            body = ("host=" + self.headers.get("Host", "") + "\n").encode()
            self._send(200, body, headers={"Content-Type": "text/plain"})
            return
        self._send(404, b"missing\n", headers={"Content-Type": "text/plain"})

    def do_PUT(self):
        size = int(self.headers.get("Content-Length", "0"))
        body = self.rfile.read(size)
        self._send(200, b"put-ack:" + body, headers={"Content-Type": "text/plain"})

    def do_POST(self):
        size = int(self.headers.get("Content-Length", "0"))
        body = self.rfile.read(size)
        self._send(200, b"post-ack:" + body, headers={"Content-Type": "text/plain"})

HTTPServer(("127.0.0.1", int(sys.argv[1])), Handler).serve_forever()
PY
  python3 "$tmpdir/server.py" "$port" >"$tmpdir/http.log" 2>&1 &
  for _ in $(seq 1 40); do
    if curl -fsS "http://127.0.0.1:$port/text" >/dev/null 2>&1; then
      return 0
    fi
    sleep 0.25
  done
  cat "$tmpdir/http.log" >&2
  return 1
}

port=18210
start_custom_server "$port"
curl -fsS -o /dev/null -w '%{num_redirects}\n' "http://127.0.0.1:$port/text" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" '0'

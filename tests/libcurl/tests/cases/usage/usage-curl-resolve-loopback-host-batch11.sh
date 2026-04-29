#!/usr/bin/env bash
# @testcase: usage-curl-resolve-loopback-host-batch11
# @title: curl resolve loopback host
# @description: Uses curl --resolve to direct a named host to a loopback server.
# @timeout: 180
# @tags: usage, curl, http
# @client: curl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-curl-resolve-loopback-host-batch11"
tmpdir=$(mktemp -d)
trap 'jobs -pr | xargs -r kill 2>/dev/null || true; rm -rf "$tmpdir"' EXIT

start_server() {
  local port=$1
  cat >"$tmpdir/server.py" <<'PYCASE'
from http.server import BaseHTTPRequestHandler, HTTPServer
import base64
import gzip
import sys

class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        return
    def send_body(self, body, extra=None):
        self.send_response(200)
        self.send_header('Content-Type', 'text/plain')
        self.send_header('Content-Length', str(len(body)))
        if extra:
            for key, value in extra.items():
                self.send_header(key, value)
        self.end_headers()
        self.wfile.write(body)
    def do_GET(self):
        if self.path.startswith('/ua'):
            self.send_body(('ua=' + self.headers.get('User-Agent', '')).encode())
        elif self.path.startswith('/cookie'):
            self.send_body(('cookie=' + self.headers.get('Cookie', '')).encode())
        elif self.path.startswith('/auth'):
            self.send_body(('auth=' + self.headers.get('Authorization', '')).encode())
        elif self.path.startswith('/gzip'):
            body = gzip.compress(b'compressed response payload\n')
            self.send_response(200)
            self.send_header('Content-Type', 'text/plain')
            self.send_header('Content-Encoding', 'gzip')
            self.send_header('Content-Length', str(len(body)))
            self.end_headers()
            self.wfile.write(body)
        elif self.path.startswith('/host'):
            self.send_body(('host=' + self.headers.get('Host', '')).encode())
        elif self.path.startswith('/query'):
            self.send_body(('path=' + self.path).encode())
        elif self.path.startswith('/etag'):
            self.send_body(b'etag body\n', {'ETag': '"validator-etag"'})
        elif self.path.startswith('/download'):
            self.send_body(b'named download\n', {'Content-Disposition': 'attachment; filename="named.txt"'})
        else:
            self.send_body(b'ok\n')
    def do_PUT(self):
        size = int(self.headers.get('Content-Length', '0'))
        self.send_body(b'put:' + self.rfile.read(size))

HTTPServer(('127.0.0.1', int(sys.argv[1])), Handler).serve_forever()
PYCASE
  python3 "$tmpdir/server.py" "$port" >"$tmpdir/server.log" 2>&1 &
  for _ in $(seq 1 40); do
    curl --noproxy '*' -fsS "http://127.0.0.1:$port/" >/dev/null 2>&1 && return 0
    sleep 0.2
  done
  cat "$tmpdir/server.log" >&2
  return 1
}

port=$((19000 + RANDOM % 2000))
start_server "$port"
base="http://127.0.0.1:$port"

curl --noproxy '*' -fsS --resolve "validator.invalid:$port:127.0.0.1" "http://validator.invalid:$port/host" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" "host=validator.invalid:$port"

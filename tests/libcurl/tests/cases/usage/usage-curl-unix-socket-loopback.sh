#!/usr/bin/env bash
# @testcase: usage-curl-unix-socket-loopback
# @title: curl --unix-socket transport
# @description: Starts a Python HTTPServer bound to a UNIX domain socket and verifies curl --unix-socket transports an HTTP GET over the AF_UNIX path.
# @timeout: 180
# @tags: usage, curl, transport
# @client: curl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-curl-unix-socket-loopback"
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

sock="$tmpdir/sock"
cat >"$tmpdir/server.py" <<PY
import os
import socket
import socketserver
from http.server import BaseHTTPRequestHandler

class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        return
    def do_GET(self):
        body = b'unix-socket-body\n'
        self.send_response(200)
        self.send_header('Content-Type', 'text/plain')
        self.send_header('Content-Length', str(len(body)))
        self.end_headers()
        self.wfile.write(body)

class UnixServer(socketserver.UnixStreamServer):
    def get_request(self):
        request, _ = self.socket.accept()
        return request, ('local', 0)

sock_path = "$sock"
if os.path.exists(sock_path):
    os.unlink(sock_path)
srv = UnixServer(sock_path, Handler)
srv.serve_forever()
PY

python3 "$tmpdir/server.py" >"$tmpdir/server.log" 2>&1 &
pid=$!
for _ in $(seq 1 50); do
  if [[ -S "$sock" ]]; then
    break
  fi
  sleep 0.1
done

curl -fsS --unix-socket "$sock" "http://localhost/" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'unix-socket-body'

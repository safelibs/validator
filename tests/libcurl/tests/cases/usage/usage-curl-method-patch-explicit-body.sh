#!/usr/bin/env bash
# @testcase: usage-curl-method-patch-explicit-body
# @title: curl -X PATCH with explicit body echo
# @description: Sends a PATCH with -X and -d against a custom handler and asserts the server echoes the method name and request body.
# @timeout: 180
# @tags: usage, curl, http, methods
# @client: curl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-curl-method-patch-explicit-body"
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
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import os

class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        return

    def _send(self, status, body=b""):
        self.send_response(status)
        self.send_header("Content-Type", "text/plain")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        if self.command != "HEAD":
            self.wfile.write(body)

    def do_GET(self):
        self._send(200, b"probe-ok\n")

    def do_PATCH(self):
        size = int(self.headers.get("Content-Length", "0"))
        body = self.rfile.read(size)
        self._send(200, b"method=PATCH\nbody=" + body + b"\n")

ThreadingHTTPServer(("127.0.0.1", int(os.environ["PORT"])), Handler).serve_forever()
PYCASE

port=$((29000 + RANDOM % 10000))
PORT="$port" python3 "$tmpdir/server.py" >"$tmpdir/server.log" 2>&1 &
pid=$!
for _ in $(seq 1 50); do
  if curl --noproxy '*' -fsS "http://127.0.0.1:$port/probe" >/dev/null 2>&1; then
    break
  fi
  sleep 0.1
done

curl --noproxy '*' -fsS -X PATCH -d 'patch-explicit-payload' "http://127.0.0.1:$port/resource" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'method=PATCH'
validator_assert_contains "$tmpdir/out" 'body=patch-explicit-payload'

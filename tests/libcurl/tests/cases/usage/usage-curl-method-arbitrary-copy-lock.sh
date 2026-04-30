#!/usr/bin/env bash
# @testcase: usage-curl-method-arbitrary-copy-lock
# @title: curl -X with arbitrary methods COPY and LOCK
# @description: Sends arbitrary HTTP methods COPY and LOCK with -X against a handler implementing dispatch via command name and asserts each is received.
# @timeout: 180
# @tags: usage, curl, http, methods
# @client: curl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-curl-method-arbitrary-copy-lock"
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

    def __getattr__(self, name):
        if name.startswith("do_"):
            method = name[3:]
            def handler():
                size = int(self.headers.get("Content-Length", "0") or "0")
                body = self.rfile.read(size) if size else b""
                payload = ("method=" + method + "\npath=" + self.path + "\n").encode() + (b"body=" + body if body else b"body=\n")
                self._send(200, payload)
            return handler
        raise AttributeError(name)

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

curl --noproxy '*' -fsS -X COPY "http://127.0.0.1:$port/source" >"$tmpdir/copy.out"
validator_assert_contains "$tmpdir/copy.out" 'method=COPY'
validator_assert_contains "$tmpdir/copy.out" 'path=/source'

curl --noproxy '*' -fsS -X LOCK "http://127.0.0.1:$port/resource" >"$tmpdir/lock.out"
validator_assert_contains "$tmpdir/lock.out" 'method=LOCK'
validator_assert_contains "$tmpdir/lock.out" 'path=/resource'

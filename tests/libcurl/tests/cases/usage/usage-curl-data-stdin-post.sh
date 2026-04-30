#!/usr/bin/env bash
# @testcase: usage-curl-data-stdin-post
# @title: curl -d @- reads POST body from stdin
# @description: Pipes a payload into curl -d @- and asserts the custom server echoes the exact body received as application/x-www-form-urlencoded.
# @timeout: 180
# @tags: usage, curl, http, post
# @client: curl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-curl-data-stdin-post"
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
        self.wfile.write(body)

    def do_GET(self):
        self._send(200, b"probe-ok\n")

    def do_POST(self):
        size = int(self.headers.get("Content-Length", "0"))
        body = self.rfile.read(size)
        ctype = self.headers.get("Content-Type", "")
        self._send(200, b"content-type=" + ctype.encode() + b"\nbody=" + body + b"\n")

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

printf 'name=stdin&value=piped-body' | curl --noproxy '*' -fsS -d @- "http://127.0.0.1:$port/echo" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'content-type=application/x-www-form-urlencoded'
validator_assert_contains "$tmpdir/out" 'body=name=stdin&value=piped-body'

#!/usr/bin/env bash
# @testcase: usage-curl-variable-expand-data
# @title: curl --variable expanded into POST data
# @description: Defines a curl 8.x --variable and references it via --expand-data so the substituted value reaches the loopback server in the POST body.
# @timeout: 180
# @tags: usage, curl, http, variable
# @client: curl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-curl-variable-expand-data"
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
        self._send(200, b"ok\n")

    def do_POST(self):
        size = int(self.headers.get("Content-Length", "0") or "0")
        body = self.rfile.read(size)
        self._send(200, b"echo:" + body)

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

curl --noproxy '*' -fsS \
  --variable 'token=variable-marker-omega' \
  --expand-data 'payload={{token}}' \
  "http://127.0.0.1:$port/post" >"$tmpdir/out"

validator_assert_contains "$tmpdir/out" 'echo:payload=variable-marker-omega'

#!/usr/bin/env bash
# @testcase: usage-curl-delete-no-body
# @title: curl DELETE with no body
# @description: Sends DELETE without any request body and verifies the server reports a zero-length body and recognises the method.
# @timeout: 180
# @tags: usage, http, cli
# @client: curl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-curl-delete-no-body"
tmpdir=$(mktemp -d)
trap 'jobs -pr | xargs -r kill 2>/dev/null || true; rm -rf "$tmpdir"' EXIT

start_server() {
  local port=$1
  cat >"$tmpdir/server.py" <<'PY'
from http.server import BaseHTTPRequestHandler, HTTPServer
import sys

class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        return
    def do_GET(self):
        body = b"ok\n"
        self.send_response(200)
        self.send_header("Content-Type", "text/plain")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)
    def do_DELETE(self):
        size = int(self.headers.get("Content-Length", "0"))
        body = ("method=" + self.command + " len=" + str(size) + "\n").encode()
        self.send_response(200)
        self.send_header("Content-Type", "text/plain")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

HTTPServer(("127.0.0.1", int(sys.argv[1])), Handler).serve_forever()
PY
  python3 "$tmpdir/server.py" "$port" >"$tmpdir/server.log" 2>&1 &
  for _ in $(seq 1 40); do
    curl -fsS "http://127.0.0.1:$port/probe" >/dev/null 2>&1 && return 0
    sleep 0.2
  done
  cat "$tmpdir/server.log" >&2
  return 1
}

port=$((22200 + RANDOM % 1000))
start_server "$port"
base="http://127.0.0.1:$port"

curl -fsS -X DELETE "$base/items/42" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'method=DELETE'
validator_assert_contains "$tmpdir/out" 'len=0'

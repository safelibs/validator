#!/usr/bin/env bash
# @testcase: usage-curl-custom-header-echoed
# @title: curl appends custom request header
# @description: Uses curl --header to add a custom request header and verifies the local server echoes its exact value back in the response body.
# @timeout: 180
# @tags: usage, http, cli
# @client: curl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-curl-custom-header-echoed"
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
        value = self.headers.get("X-Custom", "missing")
        body = ("X-Custom=" + value + "\n").encode()
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

port=$((22300 + RANDOM % 1000))
start_server "$port"
base="http://127.0.0.1:$port"

curl -fsS --header "X-Custom: hello-validator" "$base/echo" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'X-Custom=hello-validator'

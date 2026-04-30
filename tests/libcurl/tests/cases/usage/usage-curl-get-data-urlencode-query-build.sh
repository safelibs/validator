#!/usr/bin/env bash
# @testcase: usage-curl-get-data-urlencode-query-build
# @title: curl -G builds query with data-urlencode
# @description: Uses curl -G with --data-urlencode to build the query string for a GET request and verifies the local server sees the encoded fields.
# @timeout: 180
# @tags: usage, http, cli
# @client: curl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-curl-get-data-urlencode-query-build"
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
        body = self.path.encode()
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

port=$((22100 + RANDOM % 1000))
start_server "$port"
base="http://127.0.0.1:$port"

curl -fsS -G \
  --data-urlencode 'name=John Doe' \
  --data-urlencode 'tag=a&b=c' \
  "$base/search" >"$tmpdir/out"

validator_assert_contains "$tmpdir/out" '/search?'
# curl's --data-urlencode encodes spaces as '+' (form-style) and emits
# percent-encoded triplets in lowercase hex for reserved characters.
validator_assert_contains "$tmpdir/out" 'name=John+Doe'
validator_assert_contains "$tmpdir/out" 'tag=a%26b%3dc'

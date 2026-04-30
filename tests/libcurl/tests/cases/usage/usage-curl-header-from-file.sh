#!/usr/bin/env bash
# @testcase: usage-curl-header-from-file
# @title: curl reads headers from file
# @description: Uses curl --header @headerfile to load multiple custom request headers from a file and verifies the server sees each of them.
# @timeout: 180
# @tags: usage, http, cli
# @client: curl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-curl-header-from-file"
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
        a = self.headers.get("X-Alpha", "missing")
        b = self.headers.get("X-Beta", "missing")
        body = ("alpha=" + a + "\nbeta=" + b + "\n").encode()
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

port=$((22400 + RANDOM % 1000))
start_server "$port"
base="http://127.0.0.1:$port"

cat >"$tmpdir/headers.txt" <<'HDR'
X-Alpha: one
X-Beta: two-and-two
HDR

curl -fsS --header "@$tmpdir/headers.txt" "$base/echo" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'alpha=one'
validator_assert_contains "$tmpdir/out" 'beta=two-and-two'

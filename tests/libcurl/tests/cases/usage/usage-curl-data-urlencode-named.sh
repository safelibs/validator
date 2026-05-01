#!/usr/bin/env bash
# @testcase: usage-curl-data-urlencode-named
# @title: curl --data-urlencode named pair
# @description: POSTs a named --data-urlencode 'key=value with spaces' pair to a loopback server and verifies the body is percent-encoded with the key intact.
# @timeout: 180
# @tags: usage, curl, http
# @client: curl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-curl-data-urlencode-named"
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

cat >"$tmpdir/server.py" <<'PY'
from http.server import BaseHTTPRequestHandler, HTTPServer
import os

class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        return
    def do_POST(self):
        size = int(self.headers.get('Content-Length', '0'))
        body = self.rfile.read(size)
        self.send_response(200)
        self.send_header('Content-Type', 'text/plain')
        self.send_header('Content-Length', str(len(body)))
        self.end_headers()
        self.wfile.write(body)

HTTPServer(('127.0.0.1', int(os.environ['PORT'])), Handler).serve_forever()
PY

port=$((29000 + RANDOM % 10000))
PORT="$port" python3 "$tmpdir/server.py" >"$tmpdir/server.log" 2>&1 &
pid=$!
for _ in $(seq 1 50); do
  curl -fsS -o /dev/null --data 'probe=1' "http://127.0.0.1:$port/" >/dev/null 2>&1 && break
  sleep 0.1
done

curl -fsS --data-urlencode 'message=hello world & friends' "http://127.0.0.1:$port/" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'message=hello%20world%20%26%20friends'

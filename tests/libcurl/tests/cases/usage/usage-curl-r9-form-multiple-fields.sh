#!/usr/bin/env bash
# @testcase: usage-curl-r9-form-multiple-fields
# @title: curl multipart form with multiple fields
# @description: POSTs two --form fields to a loopback echo server and verifies both Content-Disposition headers and field values appear in the multipart body.
# @timeout: 180
# @tags: usage, curl, http, form
# @client: curl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
pid=""
cleanup() {
  if [[ -n "$pid" ]]; then kill "$pid" 2>/dev/null || true; wait "$pid" 2>/dev/null || true; fi
  rm -rf "$tmpdir"
}
trap cleanup EXIT

cat >"$tmpdir/server.py" <<'PY'
from http.server import BaseHTTPRequestHandler, HTTPServer
import os

class H(BaseHTTPRequestHandler):
    def log_message(self, *a, **k): pass
    def do_POST(self):
        n = int(self.headers.get('Content-Length', '0'))
        body = self.rfile.read(n)
        self.send_response(200)
        self.send_header('Content-Length', str(len(body)))
        self.end_headers()
        self.wfile.write(body)

HTTPServer(('127.0.0.1', int(os.environ['PORT'])), H).serve_forever()
PY

port=$((26500 + RANDOM % 8000))
PORT="$port" python3 "$tmpdir/server.py" >/dev/null 2>&1 &
pid=$!
for _ in $(seq 1 50); do
  curl -fsS --max-time 2 --data 'p=1' -o /dev/null "http://127.0.0.1:$port/" 2>/dev/null && break
  sleep 0.1
done

curl -fsS --max-time 5 -F 'first=alpha' -F 'second=beta' "http://127.0.0.1:$port/" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'name="first"'
validator_assert_contains "$tmpdir/out" 'alpha'
validator_assert_contains "$tmpdir/out" 'name="second"'
validator_assert_contains "$tmpdir/out" 'beta'

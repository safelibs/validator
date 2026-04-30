#!/usr/bin/env bash
# @testcase: usage-curl-config-file-load
# @title: curl loads request options from -K config file
# @description: Reads a curl -K config file containing url and header options and verifies the loopback server echoes the configured custom header.
# @timeout: 180
# @tags: usage, curl, http
# @client: curl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-curl-config-file-load"
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
from http.server import BaseHTTPRequestHandler, HTTPServer
import os
import sys

class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        return
    def do_GET(self):
        if self.path == '/echo-header':
            body = ('xv=' + self.headers.get('X-Validator', 'missing') + '\n').encode()
        elif self.path == '/probe':
            body = b'probe ok\n'
        else:
            body = b'unknown\n'
        self.send_response(200)
        self.send_header('Content-Type', 'text/plain')
        self.send_header('Content-Length', str(len(body)))
        self.end_headers()
        self.wfile.write(body)

HTTPServer(('127.0.0.1', int(os.environ['PORT'])), Handler).serve_forever()
PYCASE

port=$((29000 + RANDOM % 10000))
PORT="$port" python3 "$tmpdir/server.py" >"$tmpdir/server.log" 2>&1 &
pid=$!
for _ in $(seq 1 50); do
  if curl -fsS "http://127.0.0.1:$port/probe" >/dev/null 2>&1; then
    break
  fi
  sleep 0.1
done

cat >"$tmpdir/curlrc" <<EOF
url = "http://127.0.0.1:$port/echo-header"
header = "X-Validator: from-config"
silent
show-error
fail
EOF

curl -K "$tmpdir/curlrc" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'xv=from-config'

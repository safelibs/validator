#!/usr/bin/env bash
# @testcase: usage-curl-connect-to-loopback
# @title: curl --connect-to redirects connection to loopback
# @description: Uses curl --connect-to to send a request for a synthetic hostname through a real loopback server and verifies the original Host header is preserved.
# @timeout: 180
# @tags: usage, curl, http
# @client: curl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-curl-connect-to-loopback"
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

class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        return
    def do_GET(self):
        body = ('host=' + self.headers.get('Host', 'missing') + '\n').encode()
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
  if curl -fsS "http://127.0.0.1:$port/" >/dev/null 2>&1; then
    break
  fi
  sleep 0.1
done

curl --noproxy '*' -fsS \
     --connect-to "synthetic.validator.invalid:80:127.0.0.1:$port" \
     "http://synthetic.validator.invalid/" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'host=synthetic.validator.invalid'

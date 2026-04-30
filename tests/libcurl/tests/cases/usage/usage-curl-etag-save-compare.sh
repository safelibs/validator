#!/usr/bin/env bash
# @testcase: usage-curl-etag-save-compare
# @title: curl --etag-save writes etag then --etag-compare yields 304
# @description: Saves a server ETag with curl --etag-save and replays the request using --etag-compare so the loopback server returns HTTP 304 when the ETag still matches.
# @timeout: 180
# @tags: usage, curl, http
# @client: curl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-curl-etag-save-compare"
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

ETAG = '"validator-etag-v1"'

class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        return
    def do_GET(self):
        if self.path == '/probe':
            body = b'probe\n'
            self.send_response(200)
            self.send_header('Content-Type', 'text/plain')
            self.send_header('Content-Length', str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return
        if self.path == '/asset':
            inm = self.headers.get('If-None-Match', '')
            if inm == ETAG:
                self.send_response(304)
                self.send_header('ETag', ETAG)
                self.end_headers()
                return
            body = b'asset-payload\n'
            self.send_response(200)
            self.send_header('Content-Type', 'text/plain')
            self.send_header('ETag', ETAG)
            self.send_header('Content-Length', str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return
        self.send_response(404)
        self.end_headers()

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

curl -fsS --etag-save "$tmpdir/etag.txt" -o "$tmpdir/body1" "http://127.0.0.1:$port/asset"
validator_require_file "$tmpdir/etag.txt"
validator_assert_contains "$tmpdir/etag.txt" 'validator-etag-v1'
validator_assert_contains "$tmpdir/body1" 'asset-payload'

curl -sS --etag-compare "$tmpdir/etag.txt" -o "$tmpdir/body2" \
     -w '%{http_code}\n' "http://127.0.0.1:$port/asset" >"$tmpdir/code"
validator_assert_contains "$tmpdir/code" '304'

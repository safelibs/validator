#!/usr/bin/env bash
# @testcase: usage-curl-data-binary-no-newline-trim
# @title: curl --data-binary preserves newlines
# @description: Posts a file containing literal CRLF sequences and confirms --data-binary uploads bytes verbatim while --data would have stripped newlines, by comparing what the loopback echo server returns.
# @timeout: 180
# @tags: usage, curl, http
# @client: curl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-curl-data-binary-no-newline-trim"
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
        out = ('len=' + str(len(body)) + ' hex=' + body.hex() + '\n').encode()
        self.send_response(200)
        self.send_header('Content-Type', 'text/plain')
        self.send_header('Content-Length', str(len(out)))
        self.end_headers()
        self.wfile.write(out)

HTTPServer(('127.0.0.1', int(os.environ['PORT'])), Handler).serve_forever()
PY

port=$((29000 + RANDOM % 10000))
PORT="$port" python3 "$tmpdir/server.py" >"$tmpdir/server.log" 2>&1 &
pid=$!
for _ in $(seq 1 50); do
  curl -fsS -o /dev/null --data 'probe=1' "http://127.0.0.1:$port/" >/dev/null 2>&1 && break
  sleep 0.1
done

# Build a payload with embedded \r\n bytes via printf.
printf 'line1\r\nline2\r\n' >"$tmpdir/payload.bin"

curl -fsS --data-binary @"$tmpdir/payload.bin" "http://127.0.0.1:$port/" >"$tmpdir/binary"
# 'line1\r\nline2\r\n' is 14 bytes: 6c696e65310d0a6c696e65320d0a
validator_assert_contains "$tmpdir/binary" 'len=14'
validator_assert_contains "$tmpdir/binary" 'hex=6c696e65310d0a6c696e65320d0a'

curl -fsS --data @"$tmpdir/payload.bin" "http://127.0.0.1:$port/" >"$tmpdir/text"
# Plain --data strips newlines/CR; resulting bytes are 'line1line2' (10 bytes)
validator_assert_contains "$tmpdir/text" 'len=10'

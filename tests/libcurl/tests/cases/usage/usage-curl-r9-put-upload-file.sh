#!/usr/bin/env bash
# @testcase: usage-curl-r9-put-upload-file
# @title: curl PUT with --upload-file
# @description: Uploads a small file via PUT against a loopback server that echoes the body and verifies the request method and payload were transmitted.
# @timeout: 180
# @tags: usage, curl, http, upload
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
    def do_PUT(self):
        n = int(self.headers.get('Content-Length', '0'))
        body = self.rfile.read(n)
        out = b"METHOD=PUT\nBODY=" + body + b"\n"
        self.send_response(200)
        self.send_header('Content-Length', str(len(out)))
        self.end_headers()
        self.wfile.write(out)

HTTPServer(('127.0.0.1', int(os.environ['PORT'])), H).serve_forever()
PY

port=$((25500 + RANDOM % 8000))
PORT="$port" python3 "$tmpdir/server.py" >/dev/null 2>&1 &
pid=$!
for _ in $(seq 1 50); do
  curl -fsS --max-time 2 -X PUT --upload-file /dev/null "http://127.0.0.1:$port/" >/dev/null 2>&1 && break
  sleep 0.1
done

printf 'payload-data-xyz' >"$tmpdir/payload"
curl -fsS --max-time 5 --upload-file "$tmpdir/payload" "http://127.0.0.1:$port/target" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'METHOD=PUT'
validator_assert_contains "$tmpdir/out" 'BODY=payload-data-xyz'

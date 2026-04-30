#!/usr/bin/env bash
# @testcase: usage-curl-form-field-with-type
# @title: curl -F field with explicit content type
# @description: Submits a multipart form field with curl -F using the ;type=text/html suffix and verifies the loopback server saw the per-part Content-Type override.
# @timeout: 180
# @tags: usage, curl, http, multipart
# @client: curl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-curl-form-field-with-type"
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
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import os

class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        return

    def do_POST(self):
        size = int(self.headers.get("Content-Length", "0"))
        body = self.rfile.read(size)
        ctype = self.headers.get("Content-Type", "")
        prefix = (f"top-ctype={ctype}\n").encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/octet-stream")
        self.send_header("Content-Length", str(len(prefix) + len(body)))
        self.end_headers()
        self.wfile.write(prefix + body)

ThreadingHTTPServer(("127.0.0.1", int(os.environ["PORT"])), Handler).serve_forever()
PYCASE

port=$((29000 + RANDOM % 10000))
PORT="$port" python3 "$tmpdir/server.py" >"$tmpdir/server.log" 2>&1 &
pid=$!
for _ in $(seq 1 50); do
  if curl --noproxy '*' -fsS "http://127.0.0.1:$port/probe" >/dev/null 2>&1; then
    break
  fi
  sleep 0.1
done

printf '<p>hi</p>' >"$tmpdir/snippet.html"
curl --noproxy '*' -fsS \
  -F "snippet=@$tmpdir/snippet.html;type=text/html" \
  "http://127.0.0.1:$port/upload" >"$tmpdir/out"

validator_assert_contains "$tmpdir/out" 'top-ctype=multipart/form-data'
validator_assert_contains "$tmpdir/out" 'name="snippet"'
validator_assert_contains "$tmpdir/out" 'Content-Type: text/html'
validator_assert_contains "$tmpdir/out" '<p>hi</p>'

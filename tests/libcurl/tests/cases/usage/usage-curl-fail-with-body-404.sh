#!/usr/bin/env bash
# @testcase: usage-curl-fail-with-body-404
# @title: curl --fail-with-body returns body on HTTP 404
# @description: Verifies curl --fail-with-body writes the response body for an HTTP 404 while still exiting with the failure exit code 22.
# @timeout: 180
# @tags: usage, curl, http
# @client: curl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-curl-fail-with-body-404"
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
        if self.path == '/probe':
            body = b'probe\n'
            self.send_response(200)
        else:
            body = b'not-found-body-payload\n'
            self.send_response(404)
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

set +e
curl -sS --fail-with-body -o "$tmpdir/body" -w '%{http_code}\n' "http://127.0.0.1:$port/missing" >"$tmpdir/code"
rc=$?
set -e

if [[ "$rc" -ne 22 ]]; then
  printf 'expected exit 22, got %s\n' "$rc" >&2
  exit 1
fi
validator_assert_contains "$tmpdir/body" 'not-found-body-payload'
validator_assert_contains "$tmpdir/code" '404'

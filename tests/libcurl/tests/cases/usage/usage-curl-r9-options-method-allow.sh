#!/usr/bin/env bash
# @testcase: usage-curl-r9-options-method-allow
# @title: curl OPTIONS reads Allow header
# @description: Sends an HTTP OPTIONS request to a loopback server and verifies the Allow header is parsed and dumped to stdout via -i.
# @timeout: 180
# @tags: usage, curl, http, options
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
    def do_OPTIONS(self):
        self.send_response(204)
        self.send_header('Allow', 'GET, HEAD, OPTIONS, POST')
        self.end_headers()

HTTPServer(('127.0.0.1', int(os.environ['PORT'])), H).serve_forever()
PY

port=$((28000 + RANDOM % 8000))
PORT="$port" python3 "$tmpdir/server.py" >/dev/null 2>&1 &
pid=$!
for _ in $(seq 1 50); do
  curl -fsS --max-time 2 -o /dev/null -X OPTIONS "http://127.0.0.1:$port/" 2>/dev/null && break
  sleep 0.1
done

curl -sS --max-time 5 -i -X OPTIONS "http://127.0.0.1:$port/" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'HTTP/1.0 204'
validator_assert_contains "$tmpdir/out" 'Allow: GET, HEAD, OPTIONS, POST'

#!/usr/bin/env bash
# @testcase: usage-curl-r10-write-out-header-token
# @title: curl --write-out '%header{name}' echoes a specific response header
# @description: Hits a loopback server that emits a custom X-Validator-R10 header and asserts curl exposes its value via the %header{X-Validator-R10} write-out token.
# @timeout: 180
# @tags: usage, curl, http, write-out
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
    def do_GET(self):
        body = b"header-token-target\n"
        self.send_response(200)
        self.send_header('Content-Type', 'text/plain')
        self.send_header('X-Validator-R10', 'round-ten-value')
        self.send_header('Content-Length', str(len(body)))
        self.end_headers()
        self.wfile.write(body)

HTTPServer(('127.0.0.1', int(os.environ['PORT'])), H).serve_forever()
PY

port=$((30200 + RANDOM % 8000))
PORT="$port" python3 "$tmpdir/server.py" >/dev/null 2>&1 &
pid=$!
for _ in $(seq 1 50); do
  curl -fsS --max-time 2 -o /dev/null "http://127.0.0.1:$port/" 2>/dev/null && break
  sleep 0.1
done

value=$(curl -fsS --max-time 5 -o /dev/null -w '%header{X-Validator-R10}' "http://127.0.0.1:$port/")
[[ "$value" == "round-ten-value" ]] || {
  printf 'expected header value round-ten-value, got %q\n' "$value" >&2
  exit 1
}

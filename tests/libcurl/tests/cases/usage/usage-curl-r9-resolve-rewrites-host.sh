#!/usr/bin/env bash
# @testcase: usage-curl-r9-resolve-rewrites-host
# @title: curl --resolve rewrites a custom host
# @description: Uses --resolve to point a synthetic hostname at 127.0.0.1 and verifies the request reaches a local server while the Host header reflects the synthetic name.
# @timeout: 180
# @tags: usage, curl, http, dns
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
        host = self.headers.get('Host', '')
        body = ("HOST=" + host + "\n").encode()
        self.send_response(200)
        self.send_header('Content-Length', str(len(body)))
        self.end_headers()
        self.wfile.write(body)

HTTPServer(('127.0.0.1', int(os.environ['PORT'])), H).serve_forever()
PY

port=$((27500 + RANDOM % 8000))
PORT="$port" python3 "$tmpdir/server.py" >/dev/null 2>&1 &
pid=$!
for _ in $(seq 1 50); do
  curl -fsS --max-time 2 -o /dev/null "http://127.0.0.1:$port/" 2>/dev/null && break
  sleep 0.1
done

curl -fsS --max-time 5 --resolve "validator.invalid:$port:127.0.0.1" "http://validator.invalid:$port/" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" "HOST=validator.invalid:$port"

#!/usr/bin/env bash
# @testcase: usage-curl-r10-oauth2-bearer-header
# @title: curl --oauth2-bearer adds Authorization Bearer header
# @description: Sends --oauth2-bearer with a sample token to a loopback server that echoes the request Authorization header, and asserts the header equals "Bearer <token>".
# @timeout: 180
# @tags: usage, curl, http, auth
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
        auth = self.headers.get('Authorization', '')
        body = ("AUTH=" + auth + "\n").encode()
        self.send_response(200)
        self.send_header('Content-Length', str(len(body)))
        self.end_headers()
        self.wfile.write(body)

HTTPServer(('127.0.0.1', int(os.environ['PORT'])), H).serve_forever()
PY

port=$((29200 + RANDOM % 8000))
PORT="$port" python3 "$tmpdir/server.py" >/dev/null 2>&1 &
pid=$!
for _ in $(seq 1 50); do
  curl -fsS --max-time 2 -o /dev/null "http://127.0.0.1:$port/" 2>/dev/null && break
  sleep 0.1
done

token='r10-token-7eS7e'
curl -fsS --max-time 5 --oauth2-bearer "$token" "http://127.0.0.1:$port/" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" "AUTH=Bearer $token"

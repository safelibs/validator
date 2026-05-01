#!/usr/bin/env bash
# @testcase: usage-curl-location-trusted-auth-forward
# @title: curl --location-trusted forwards credentials
# @description: Redirects from /start to /target on the same loopback host and verifies curl --location-trusted -u forwards the Authorization header to the redirected request, while plain --location does not.
# @timeout: 180
# @tags: usage, curl, http, auth
# @client: curl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-curl-location-trusted-auth-forward"
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
    def do_GET(self):
        if self.path == '/start':
            self.send_response(302)
            self.send_header('Location', '/target')
            self.end_headers()
            return
        body = ('auth=' + self.headers.get('Authorization', 'absent') + '\n').encode()
        self.send_response(200)
        self.send_header('Content-Type', 'text/plain')
        self.send_header('Content-Length', str(len(body)))
        self.end_headers()
        self.wfile.write(body)

HTTPServer(('127.0.0.1', int(os.environ['PORT'])), Handler).serve_forever()
PY

port=$((29000 + RANDOM % 10000))
PORT="$port" python3 "$tmpdir/server.py" >"$tmpdir/server.log" 2>&1 &
pid=$!
for _ in $(seq 1 50); do
  curl -fsS "http://127.0.0.1:$port/target" >/dev/null 2>&1 && break
  sleep 0.1
done

curl -fsS --location-trusted -u 'alice:opensesame' "http://127.0.0.1:$port/start" >"$tmpdir/trusted"
validator_assert_contains "$tmpdir/trusted" 'auth=Basic'

curl -fsS --location -u 'alice:opensesame' "http://127.0.0.1:$port/start" >"$tmpdir/plain"
validator_assert_contains "$tmpdir/plain" 'auth=absent'

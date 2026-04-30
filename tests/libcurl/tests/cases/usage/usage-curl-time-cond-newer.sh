#!/usr/bin/env bash
# @testcase: usage-curl-time-cond-newer
# @title: curl --time-cond sends If-Modified-Since header
# @description: Uses curl --time-cond with an explicit RFC 1123 timestamp and verifies the loopback server observes a matching If-Modified-Since request header and returns 200 with the payload.
# @timeout: 180
# @tags: usage, curl, http, conditional
# @client: curl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-curl-time-cond-newer"
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

    def _send(self, status, body=b""):
        self.send_response(status)
        self.send_header("Content-Type", "text/plain")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        ims = self.headers.get("If-Modified-Since", "missing")
        body = ("if-modified-since=" + ims + "\nresource-body\n").encode()
        self._send(200, body)

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

# Pass an explicit RFC 1123 timestamp so the test is deterministic.
ts='Wed, 21 Oct 2015 07:28:00 GMT'

http_code=$(curl --noproxy '*' -sS \
  --time-cond "$ts" \
  -o "$tmpdir/out" -w '%{http_code}' \
  "http://127.0.0.1:$port/resource")

[[ "$http_code" == "200" ]] || {
  printf 'expected http_code 200, got %s\n' "$http_code" >&2
  exit 1
}

validator_assert_contains "$tmpdir/out" 'if-modified-since=Wed, 21 Oct 2015 07:28:00 GMT'
validator_assert_contains "$tmpdir/out" 'resource-body'

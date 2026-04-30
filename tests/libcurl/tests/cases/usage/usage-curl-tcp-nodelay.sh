#!/usr/bin/env bash
# @testcase: usage-curl-tcp-nodelay
# @title: curl --tcp-nodelay completes a loopback transfer with 200
# @description: Issues a curl request with --tcp-nodelay to a loopback server and verifies the response body and http_code are returned correctly with TCP_NODELAY enabled.
# @timeout: 180
# @tags: usage, curl, http, tcp
# @client: curl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-curl-tcp-nodelay"
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
        self._send(200, b"nodelay-payload\n")

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

http_code=$(curl --noproxy '*' -sS --tcp-nodelay \
  -o "$tmpdir/out" -w '%{http_code}' \
  "http://127.0.0.1:$port/fast")

[[ "$http_code" == "200" ]] || {
  printf 'expected http_code 200, got %s\n' "$http_code" >&2
  exit 1
}

validator_assert_contains "$tmpdir/out" 'nodelay-payload'

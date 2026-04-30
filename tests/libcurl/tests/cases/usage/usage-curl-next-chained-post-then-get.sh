#!/usr/bin/env bash
# @testcase: usage-curl-next-chained-post-then-get
# @title: curl --next chained POST then GET
# @description: Chains a POST and a GET in a single curl invocation using --next to reset request options, and verifies both responses are written to their respective output files.
# @timeout: 180
# @tags: usage, curl, http
# @client: curl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-curl-next-chained-post-then-get"
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
        self._send(200, ("get-path=" + self.path + "\n").encode())

    def do_POST(self):
        size = int(self.headers.get("Content-Length", "0") or "0")
        body = self.rfile.read(size)
        self._send(200, b"post-echo:" + body + b"\n")

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

curl --noproxy '*' -fsS \
  -o "$tmpdir/post.out" -X POST --data 'chunk-payload' "http://127.0.0.1:$port/submit" \
  --next \
  -o "$tmpdir/get.out" "http://127.0.0.1:$port/fetch"

validator_assert_contains "$tmpdir/post.out" 'post-echo:chunk-payload'
validator_assert_contains "$tmpdir/get.out" 'get-path=/fetch'

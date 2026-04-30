#!/usr/bin/env bash
# @testcase: usage-curl-tcp-fastopen-accepted
# @title: curl --tcp-fastopen accepted on plain HTTP
# @description: Confirms --tcp-fastopen is accepted by curl and the underlying transfer still completes successfully against a loopback server.
# @timeout: 180
# @tags: usage, curl, connection
# @client: curl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-curl-tcp-fastopen-accepted"
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

    def do_GET(self):
        body = b"tcp-fastopen-body\n"
        self.send_response(200)
        self.send_header("Content-Type", "text/plain")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

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

curl --noproxy '*' -fsS --tcp-fastopen -o "$tmpdir/body" -w '%{http_code}\n' "http://127.0.0.1:$port/tfo" >"$tmpdir/code"
validator_assert_contains "$tmpdir/body" 'tcp-fastopen-body'
validator_assert_contains "$tmpdir/code" '200'

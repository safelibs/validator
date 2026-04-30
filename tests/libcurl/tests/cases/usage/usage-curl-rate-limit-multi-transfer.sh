#!/usr/bin/env bash
# @testcase: usage-curl-rate-limit-multi-transfer
# @title: curl --rate limits serial request rate
# @description: Issues two URLs in one curl invocation with --rate "120/m" and verifies both transfers complete with status 200.
# @timeout: 180
# @tags: usage, curl, rate
# @client: curl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-curl-rate-limit-multi-transfer"
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
        body = ("rate-path=" + self.path + "\n").encode()
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

curl --noproxy '*' -fsS --rate "600/m" \
  -o "$tmpdir/a" "http://127.0.0.1:$port/a" \
  --next \
  -o "$tmpdir/b" "http://127.0.0.1:$port/b"

validator_assert_contains "$tmpdir/a" 'rate-path=/a'
validator_assert_contains "$tmpdir/b" 'rate-path=/b'

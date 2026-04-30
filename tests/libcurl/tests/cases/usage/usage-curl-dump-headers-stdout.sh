#!/usr/bin/env bash
# @testcase: usage-curl-dump-headers-stdout
# @title: curl -D - dumps headers to stdout
# @description: Asks curl to write response headers to stdout via -D - while sending the body to a file, and verifies status line, headers, and body all land in the expected streams.
# @timeout: 180
# @tags: usage, curl, http
# @client: curl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-curl-dump-headers-stdout"
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
    protocol_version = "HTTP/1.1"

    def log_message(self, fmt, *args):
        return

    def do_GET(self):
        body = b"dump-headers-stdout-body\n"
        self.send_response(200)
        self.send_header("Content-Type", "text/plain")
        self.send_header("X-Validator-Marker", "dumped")
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

curl --noproxy '*' -fsS -D - "http://127.0.0.1:$port/dump" -o "$tmpdir/body" >"$tmpdir/headers"
validator_assert_contains "$tmpdir/headers" 'HTTP/1.1 200'
validator_assert_contains "$tmpdir/headers" 'X-Validator-Marker: dumped'
validator_assert_contains "$tmpdir/headers" 'Content-Type: text/plain'
validator_assert_contains "$tmpdir/body" 'dump-headers-stdout-body'
# Body must not have leaked into the header stream.
if grep -F 'dump-headers-stdout-body' "$tmpdir/headers" >/dev/null; then
  printf 'body unexpectedly appeared in -D - header dump\n' >&2
  exit 1
fi

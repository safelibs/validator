#!/usr/bin/env bash
# @testcase: usage-curl-form-file-stdin-multipart
# @title: curl --form file=@- reads multipart part from stdin
# @description: Streams a payload into curl --form 'file=@-;type=text/plain' and asserts the custom server receives a multipart/form-data POST whose part body matches the stdin payload exactly.
# @timeout: 180
# @tags: usage, curl, http, multipart
# @client: curl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-curl-form-file-stdin-multipart"
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
        self._send(200, b"probe-ok\n")

    def do_POST(self):
        size = int(self.headers.get("Content-Length", "0"))
        body = self.rfile.read(size)
        ctype = self.headers.get("Content-Type", "")
        # echo content-type plus a marker line then raw body so the test can grep it
        self._send(200, b"content-type=" + ctype.encode() + b"\n---body---\n" + body)

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

printf 'multipart-from-stdin-payload\n' | \
  curl --noproxy '*' -fsS --form 'file=@-;type=text/plain' "http://127.0.0.1:$port/upload" >"$tmpdir/out"

validator_assert_contains "$tmpdir/out" 'content-type=multipart/form-data; boundary='
validator_assert_contains "$tmpdir/out" 'Content-Disposition: form-data; name="file"'
validator_assert_contains "$tmpdir/out" 'Content-Type: text/plain'
validator_assert_contains "$tmpdir/out" 'multipart-from-stdin-payload'

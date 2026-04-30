#!/usr/bin/env bash
# @testcase: usage-curl-multipart-explicit-boundary
# @title: curl -F multipart includes well-formed boundary in echoed body
# @description: Posts a curl multipart form, captures the loopback echo of the request body, and verifies both the Content-Type boundary parameter and the matching multipart delimiter line appear in the echoed payload.
# @timeout: 180
# @tags: usage, curl, http, multipart
# @client: curl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-curl-multipart-explicit-boundary"
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
        size = int(self.headers.get("Content-Length", "0") or "0")
        raw = self.rfile.read(size)
        ctype = self.headers.get("Content-Type", "")
        body = b"content-type=" + ctype.encode() + b"\n" + b"body=" + raw + b"\n"
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

http_code=$(curl --noproxy '*' -sS \
  -F 'field=marker-value' \
  -F 'note=second-part' \
  -o "$tmpdir/out" -w '%{http_code}' \
  "http://127.0.0.1:$port/upload")

[[ "$http_code" == "200" ]] || {
  printf 'expected http_code 200, got %s\n' "$http_code" >&2
  exit 1
}

# Extract the boundary token reported in the echoed Content-Type line.
boundary=$(sed -n 's/^content-type=multipart\/form-data; boundary=//p' "$tmpdir/out" | head -n1 | tr -d '\r')
[[ -n "$boundary" ]] || {
  printf 'no multipart boundary found in echoed content-type\n' >&2
  sed -n '1,10p' "$tmpdir/out" >&2
  exit 1
}

validator_assert_contains "$tmpdir/out" "content-type=multipart/form-data; boundary=$boundary"
validator_assert_contains "$tmpdir/out" "--$boundary"
validator_assert_contains "$tmpdir/out" 'name="field"'
validator_assert_contains "$tmpdir/out" 'marker-value'
validator_assert_contains "$tmpdir/out" 'name="note"'
validator_assert_contains "$tmpdir/out" 'second-part'

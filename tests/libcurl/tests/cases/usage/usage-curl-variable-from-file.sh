#!/usr/bin/env bash
# @testcase: usage-curl-variable-from-file
# @title: curl --variable name@file expands file contents into a header
# @description: Defines a curl 8.x --variable from a file (name@path) and expands it into a request header so the loopback server sees the file's contents in the echoed header value.
# @timeout: 180
# @tags: usage, curl, http, variable
# @client: curl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-curl-variable-from-file"
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
        marker = self.headers.get("X-Validator-Token", "missing")
        self._send(200, ("token=" + marker + "\n").encode())

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

# The value lives only in this file; --variable name@file pulls it in.
printf 'file-loaded-token-9X' >"$tmpdir/secret.txt"

http_code=$(curl --noproxy '*' -sS \
  --variable "token@$tmpdir/secret.txt" \
  --expand-header 'X-Validator-Token: {{token}}' \
  -o "$tmpdir/out" -w '%{http_code}' \
  "http://127.0.0.1:$port/echo")

[[ "$http_code" == "200" ]] || {
  printf 'expected http_code 200, got %s\n' "$http_code" >&2
  exit 1
}

validator_assert_contains "$tmpdir/out" 'token=file-loaded-token-9X'

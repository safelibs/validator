#!/usr/bin/env bash
# @testcase: usage-curl-max-filesize-exceeded
# @title: curl --max-filesize aborts with exit 63
# @description: Requests a body larger than --max-filesize from a custom server and asserts curl exits with status 63 (CURLE_FILESIZE_EXCEEDED).
# @timeout: 180
# @tags: usage, curl, http, limits
# @client: curl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-curl-max-filesize-exceeded"
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
        if self.path == "/probe":
            body = b"probe\n"
        else:
            body = b"X" * 4096
        self.send_response(200)
        self.send_header("Content-Type", "application/octet-stream")
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

set +e
curl --noproxy '*' -sS --max-filesize 256 -o "$tmpdir/body" "http://127.0.0.1:$port/large" 2>"$tmpdir/err"
rc=$?
set -e

if [[ "$rc" -ne 63 ]]; then
  printf 'expected exit 63, got %s\n' "$rc" >&2
  cat "$tmpdir/err" >&2 || true
  exit 1
fi

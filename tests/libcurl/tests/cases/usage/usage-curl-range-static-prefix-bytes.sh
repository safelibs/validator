#!/usr/bin/env bash
# @testcase: usage-curl-range-static-prefix-bytes
# @title: curl --range 0-3 reads file prefix
# @description: Requests bytes 0-3 of a static loopback resource via --range and verifies only the first four bytes of the body are returned.
# @timeout: 180
# @tags: usage, curl, range
# @client: curl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-curl-range-static-prefix-bytes"
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

FULL = b"ABCDEFGHIJKLMNOP"

class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        return

    def do_GET(self):
        if self.path == "/probe":
            self.send_response(200)
            self.send_header("Content-Type", "text/plain")
            self.send_header("Content-Length", "3")
            self.end_headers()
            self.wfile.write(b"ok\n")
            return
        req_range = self.headers.get("Range", "")
        if req_range.startswith("bytes="):
            spec = req_range.split("=", 1)[1]
            start_s, _, end_s = spec.partition("-")
            start = int(start_s)
            end = int(end_s) if end_s else len(FULL) - 1
            chunk = FULL[start:end + 1]
            self.send_response(206)
            self.send_header("Content-Type", "application/octet-stream")
            self.send_header("Content-Range", f"bytes {start}-{end}/{len(FULL)}")
            self.send_header("Content-Length", str(len(chunk)))
            self.end_headers()
            self.wfile.write(chunk)
            return
        self.send_response(200)
        self.send_header("Content-Type", "application/octet-stream")
        self.send_header("Content-Length", str(len(FULL)))
        self.end_headers()
        self.wfile.write(FULL)

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

curl --noproxy '*' -fsS --range 0-3 -o "$tmpdir/prefix" "http://127.0.0.1:$port/data"
size=$(wc -c <"$tmpdir/prefix" | tr -d ' ')
[[ "$size" == "4" ]] || {
  printf 'expected 4-byte prefix, got %s bytes\n' "$size" >&2
  od -c "$tmpdir/prefix" >&2
  exit 1
}
content=$(cat "$tmpdir/prefix")
[[ "$content" == "ABCD" ]] || {
  printf 'expected prefix ABCD, got %s\n' "$content" >&2
  exit 1
}

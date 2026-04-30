#!/usr/bin/env bash
# @testcase: usage-curl-range-from-offset
# @title: curl --range starting from middle of file
# @description: Issues an open-ended range starting from a middle offset with curl --range and verifies the loopback server returned only the suffix bytes.
# @timeout: 180
# @tags: usage, curl, range
# @client: curl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-curl-range-from-offset"
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
import re

BODY = b"ABCDEFGHIJKLMNOPQRST"

class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        return

    def do_GET(self):
        rng = self.headers.get("Range", "")
        m = re.match(r"^bytes=(\d+)-(\d*)$", rng)
        if m:
            start = int(m.group(1))
            end = int(m.group(2)) if m.group(2) else len(BODY) - 1
            chunk = BODY[start:end + 1]
            self.send_response(206)
            self.send_header("Content-Type", "application/octet-stream")
            self.send_header("Content-Range", f"bytes {start}-{end}/{len(BODY)}")
            self.send_header("Content-Length", str(len(chunk)))
            self.end_headers()
            self.wfile.write(chunk)
            return
        self.send_response(200)
        self.send_header("Content-Type", "application/octet-stream")
        self.send_header("Content-Length", str(len(BODY)))
        self.end_headers()
        self.wfile.write(BODY)

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

curl --noproxy '*' -fsS --range 10- "http://127.0.0.1:$port/data" -D "$tmpdir/headers" -o "$tmpdir/body"
validator_assert_contains "$tmpdir/headers" '206'
validator_assert_contains "$tmpdir/headers" 'bytes 10-19/20'
got=$(cat "$tmpdir/body")
[[ "$got" == "KLMNOPQRST" ]] || {
  printf 'expected suffix KLMNOPQRST, got: %q\n' "$got" >&2
  exit 1
}

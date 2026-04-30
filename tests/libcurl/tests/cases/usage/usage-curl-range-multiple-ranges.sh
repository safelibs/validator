#!/usr/bin/env bash
# @testcase: usage-curl-range-multiple-ranges
# @title: curl --range with multiple ranges
# @description: Issues a multi-range request with curl --range and verifies the loopback server returned a 206 multipart/byteranges body containing every requested slice.
# @timeout: 180
# @tags: usage, curl, range
# @client: curl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-curl-range-multiple-ranges"
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

BODY = b"0123456789abcdefghij"
BOUNDARY = "validator-mp-boundary"

class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        return

    def do_GET(self):
        rng = self.headers.get("Range", "")
        if not rng.startswith("bytes="):
            self.send_response(200)
            self.send_header("Content-Type", "application/octet-stream")
            self.send_header("Content-Length", str(len(BODY)))
            self.end_headers()
            self.wfile.write(BODY)
            return
        spec = rng.split("=", 1)[1]
        ranges = []
        for piece in spec.split(","):
            piece = piece.strip()
            m = re.match(r"^(\d+)-(\d+)$", piece)
            if not m:
                continue
            start = int(m.group(1))
            end = int(m.group(2))
            ranges.append((start, end))
        if len(ranges) <= 1:
            start, end = ranges[0]
            chunk = BODY[start:end + 1]
            self.send_response(206)
            self.send_header("Content-Type", "application/octet-stream")
            self.send_header("Content-Range", f"bytes {start}-{end}/{len(BODY)}")
            self.send_header("Content-Length", str(len(chunk)))
            self.end_headers()
            self.wfile.write(chunk)
            return
        parts = []
        for start, end in ranges:
            chunk = BODY[start:end + 1]
            part = (
                f"--{BOUNDARY}\r\n"
                f"Content-Type: application/octet-stream\r\n"
                f"Content-Range: bytes {start}-{end}/{len(BODY)}\r\n\r\n"
            ).encode() + chunk + b"\r\n"
            parts.append(part)
        parts.append(f"--{BOUNDARY}--\r\n".encode())
        body = b"".join(parts)
        self.send_response(206)
        self.send_header("Content-Type", f"multipart/byteranges; boundary={BOUNDARY}")
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

curl --noproxy '*' -fsS --range 0-2,8-10 "http://127.0.0.1:$port/data" -D "$tmpdir/headers" -o "$tmpdir/body"
validator_assert_contains "$tmpdir/headers" '206'
validator_assert_contains "$tmpdir/headers" 'multipart/byteranges'
validator_assert_contains "$tmpdir/body" 'validator-mp-boundary'
validator_assert_contains "$tmpdir/body" '012'
validator_assert_contains "$tmpdir/body" '89a'
validator_assert_contains "$tmpdir/body" 'bytes 0-2/20'
validator_assert_contains "$tmpdir/body" 'bytes 8-10/20'

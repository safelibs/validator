#!/usr/bin/env bash
# @testcase: usage-curl-continue-at-resume
# @title: curl --continue-at resumes a partial download via Range
# @description: Pre-seeds an output file with a known prefix, invokes curl --continue-at to resume the transfer using a Range request to a loopback server, and verifies the assembled file matches the full payload while the resumed status is 206.
# @timeout: 180
# @tags: usage, curl, http, range, resume
# @client: curl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-curl-continue-at-resume"
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

PAYLOAD = b"abcdefghijklmnopqrstuvwxyz0123456789"  # 36 bytes

class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        return

    def _send(self, status, body=b"", headers=None):
        self.send_response(status)
        for key, value in (headers or {}).items():
            self.send_header(key, value)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        if self.path != "/payload":
            self._send(200, b"probe-ok\n", {"Content-Type": "text/plain"})
            return
        rng = self.headers.get("Range", "")
        total = len(PAYLOAD)
        if rng.startswith("bytes="):
            spec = rng.split("=", 1)[1]
            start_s, _, end_s = spec.partition("-")
            start = int(start_s)
            end = int(end_s) if end_s else total - 1
            chunk = PAYLOAD[start:end + 1]
            self._send(206, chunk, {
                "Content-Type": "application/octet-stream",
                "Content-Range": f"bytes {start}-{end}/{total}",
                "Accept-Ranges": "bytes",
            })
            return
        self._send(200, PAYLOAD, {
            "Content-Type": "application/octet-stream",
            "Accept-Ranges": "bytes",
        })

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

# Pre-seed first 10 bytes so curl --continue-at 10 must request the rest.
printf 'abcdefghij' >"$tmpdir/body"

http_code=$(curl --noproxy '*' -sS \
  --continue-at 10 \
  -o "$tmpdir/body" -w '%{http_code}' \
  "http://127.0.0.1:$port/payload")

[[ "$http_code" == "206" ]] || {
  printf 'expected http_code 206 (partial), got %s\n' "$http_code" >&2
  exit 1
}

actual=$(cat "$tmpdir/body")
expected='abcdefghijklmnopqrstuvwxyz0123456789'
[[ "$actual" == "$expected" ]] || {
  printf 'resumed body mismatch:\n  expected: %s\n  actual:   %s\n' "$expected" "$actual" >&2
  exit 1
}

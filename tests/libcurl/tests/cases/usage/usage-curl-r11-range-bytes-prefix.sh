#!/usr/bin/env bash
# @testcase: usage-curl-r11-range-bytes-prefix
# @title: curl --range 0-3 fetches only the first four bytes of a Range-aware server
# @description: Hosts a 20-byte payload behind a custom loopback handler that honors the Range header and asserts curl --range 0-3 returns exactly the first four bytes "0123" with HTTP 206.
# @timeout: 180
# @tags: usage, curl, http, range
# @client: curl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
pid=""
cleanup() {
  if [[ -n "$pid" ]]; then kill "$pid" 2>/dev/null || true; wait "$pid" 2>/dev/null || true; fi
  rm -rf "$tmpdir"
}
trap cleanup EXIT

cat >"$tmpdir/server.py" <<'PY'
from http.server import BaseHTTPRequestHandler, HTTPServer
import os
class H(BaseHTTPRequestHandler):
    def log_message(self, *a, **k): pass
    def do_GET(self):
        body = b'0123456789abcdefghij'
        rng = self.headers.get('Range')
        if rng and rng.startswith('bytes='):
            a, b = rng[6:].split('-')
            a = int(a) if a else 0
            b = int(b) if b else len(body) - 1
            part = body[a:b+1]
            self.send_response(206)
            self.send_header('Content-Type', 'application/octet-stream')
            self.send_header('Content-Range', f'bytes {a}-{b}/{len(body)}')
            self.send_header('Content-Length', str(len(part)))
            self.end_headers()
            self.wfile.write(part)
        else:
            self.send_response(200)
            self.send_header('Content-Type', 'application/octet-stream')
            self.send_header('Accept-Ranges', 'bytes')
            self.send_header('Content-Length', str(len(body)))
            self.end_headers()
            self.wfile.write(body)
HTTPServer(('127.0.0.1', int(os.environ['PORT'])), H).serve_forever()
PY

port=$((29000 + RANDOM % 8000))
PORT="$port" python3 "$tmpdir/server.py" >/dev/null 2>&1 &
pid=$!
for _ in $(seq 1 50); do
  curl -fsS --max-time 2 -o /dev/null "http://127.0.0.1:$port/" 2>/dev/null && break
  sleep 0.1
done

code=$(curl -sS --max-time 5 --range 0-3 -o "$tmpdir/part.bin" -w '%{response_code}' "http://127.0.0.1:$port/")
[[ "$code" == "206" ]] || {
  printf 'expected response_code 206, got %q\n' "$code" >&2
  exit 1
}
[[ "$(wc -c <"$tmpdir/part.bin")" == "4" ]] || {
  printf 'expected 4 bytes in response body, got %d\n' "$(wc -c <"$tmpdir/part.bin")" >&2
  exit 1
}
[[ "$(cat "$tmpdir/part.bin")" == "0123" ]] || {
  printf 'expected body 0123, got %q\n' "$(cat "$tmpdir/part.bin")" >&2
  exit 1
}

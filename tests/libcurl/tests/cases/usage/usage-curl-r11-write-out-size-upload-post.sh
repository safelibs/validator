#!/usr/bin/env bash
# @testcase: usage-curl-r11-write-out-size-upload-post
# @title: curl --write-out '%{size_upload}' equals the POST body byte count
# @description: POSTs a fixed 17-byte payload via --data-binary to a loopback server and asserts %{size_upload} reports exactly 17 bytes uploaded.
# @timeout: 180
# @tags: usage, curl, http, write-out, post
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
    def do_POST(self):
        n = int(self.headers.get('Content-Length', '0'))
        _ = self.rfile.read(n)
        body = b'ok\n'
        self.send_response(200)
        self.send_header('Content-Type', 'text/plain')
        self.send_header('Content-Length', str(len(body)))
        self.end_headers()
        self.wfile.write(body)
HTTPServer(('127.0.0.1', int(os.environ['PORT'])), H).serve_forever()
PY

port=$((28600 + RANDOM % 8000))
PORT="$port" python3 "$tmpdir/server.py" >/dev/null 2>&1 &
pid=$!
for _ in $(seq 1 50); do
  curl -fsS --max-time 2 -X POST --data-binary 'warmup' -o /dev/null "http://127.0.0.1:$port/" 2>/dev/null && break
  sleep 0.1
done

# Body of exactly 17 bytes.
payload='aaaaabbbbbcccccdd'
[[ ${#payload} -eq 17 ]] || { echo "fixture payload size drift" >&2; exit 1; }

n=$(curl -sS --max-time 5 -X POST --data-binary "$payload" -o /dev/null -w '%{size_upload}' "http://127.0.0.1:$port/")
[[ "$n" == "17" ]] || {
  printf 'expected size_upload 17, got %q\n' "$n" >&2
  exit 1
}

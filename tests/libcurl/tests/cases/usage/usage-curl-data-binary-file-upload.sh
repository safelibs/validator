#!/usr/bin/env bash
# @testcase: usage-curl-data-binary-file-upload
# @title: curl --data-binary @file binary upload
# @description: Posts the contents of a binary file with curl --data-binary @file and verifies the loopback server received the bytes verbatim with no newline mangling.
# @timeout: 180
# @tags: usage, curl, http
# @client: curl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-curl-data-binary-file-upload"
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

    def do_POST(self):
        size = int(self.headers.get("Content-Length", "0"))
        body = self.rfile.read(size)
        ctype = self.headers.get("Content-Type", "")
        out = (f"len={size}\nctype={ctype}\n").encode() + b"body=" + body
        self.send_response(200)
        self.send_header("Content-Type", "application/octet-stream")
        self.send_header("Content-Length", str(len(out)))
        self.end_headers()
        self.wfile.write(out)

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

# Binary payload with embedded LF, NUL, and high bytes — --data-binary must
# transmit it byte-exact (unlike --data which strips newlines).
python3 - "$tmpdir/payload.bin" <<'PY'
import sys
with open(sys.argv[1], "wb") as fh:
    fh.write(b"line1\nline2\n\x00\x01\x02\xfe\xff\nline3\n")
PY

expected_size=$(stat -c '%s' "$tmpdir/payload.bin")

curl --noproxy '*' -fsS --data-binary "@$tmpdir/payload.bin" \
  "http://127.0.0.1:$port/upload" -o "$tmpdir/out"

validator_assert_contains "$tmpdir/out" "len=$expected_size"
validator_assert_contains "$tmpdir/out" 'ctype=application/x-www-form-urlencoded'
validator_assert_contains "$tmpdir/out" 'line1'
validator_assert_contains "$tmpdir/out" 'line2'
validator_assert_contains "$tmpdir/out" 'line3'

# Also confirm the original payload bytes appear after the "body=" marker.
python3 - "$tmpdir/out" "$tmpdir/payload.bin" <<'PY'
import sys
out = open(sys.argv[1], "rb").read()
payload = open(sys.argv[2], "rb").read()
marker = b"body="
idx = out.find(marker)
if idx < 0:
    sys.exit("missing body marker in server response")
got = out[idx + len(marker):]
if got != payload:
    sys.exit(f"body mismatch: expected {len(payload)} bytes, got {len(got)}")
PY

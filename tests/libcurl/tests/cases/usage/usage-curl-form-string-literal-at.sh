#!/usr/bin/env bash
# @testcase: usage-curl-form-string-literal-at
# @title: curl --form-string preserves leading @ literally
# @description: Submits a multipart field whose value begins with @ via curl --form-string and verifies the literal characters are sent (not interpreted as a file reference like -F would).
# @timeout: 180
# @tags: usage, curl, http, multipart
# @client: curl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-curl-form-string-literal-at"
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
        prefix = (f"top-ctype={ctype}\n").encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/octet-stream")
        self.send_header("Content-Length", str(len(prefix) + len(body)))
        self.end_headers()
        self.wfile.write(prefix + body)

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

# A path that exists on disk would get read by -F; --form-string must NOT.
echo "secret-real-content" >"$tmpdir/should-not-be-read.txt"

curl --noproxy '*' -fsS \
  --form-string "payload=@$tmpdir/should-not-be-read.txt" \
  "http://127.0.0.1:$port/upload" >"$tmpdir/out"

validator_assert_contains "$tmpdir/out" 'top-ctype=multipart/form-data'
validator_assert_contains "$tmpdir/out" 'name="payload"'
# The literal "@..." string must appear in the body.
validator_assert_contains "$tmpdir/out" "@$tmpdir/should-not-be-read.txt"
# And the file's contents must NOT have leaked into the body.
if grep -F 'secret-real-content' "$tmpdir/out" >/dev/null; then
  printf '--form-string unexpectedly read the @file contents\n' >&2
  exit 1
fi
# --form-string must not emit a per-part filename= attribute either.
if grep -F 'filename=' "$tmpdir/out" >/dev/null; then
  printf '--form-string unexpectedly emitted a filename= attribute\n' >&2
  exit 1
fi

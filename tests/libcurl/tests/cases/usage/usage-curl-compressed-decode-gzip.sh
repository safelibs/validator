#!/usr/bin/env bash
# @testcase: usage-curl-compressed-decode-gzip
# @title: curl --compressed decodes gzip body
# @description: Drives curl --compressed against a loopback server returning gzip-encoded bytes and verifies the decoded plaintext payload appears in stdout.
# @timeout: 180
# @tags: usage, curl, http, compression
# @client: curl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-curl-compressed-decode-gzip"
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
import gzip
import os

PLAIN = b"compressed-plaintext-marker-zeta\n"

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
        body = gzip.compress(PLAIN)
        self.send_response(200)
        self.send_header("Content-Type", "text/plain")
        self.send_header("Content-Encoding", "gzip")
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

curl --noproxy '*' -fsS --compressed "http://127.0.0.1:$port/gz" >"$tmpdir/decoded"
validator_assert_contains "$tmpdir/decoded" 'compressed-plaintext-marker-zeta'

# Sanity: without --compressed, body is still gzip framed (magic 1f 8b)
curl --noproxy '*' -fsS "http://127.0.0.1:$port/gz" >"$tmpdir/raw"
head -c 2 "$tmpdir/raw" | od -An -tx1 | tr -d ' \n' >"$tmpdir/raw.hex"
validator_assert_contains "$tmpdir/raw.hex" '1f8b'

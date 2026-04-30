#!/usr/bin/env bash
# @testcase: usage-curl-location-relative-redirect
# @title: curl --location follows a relative redirect target
# @description: Follows a 302 redirect whose Location header is a relative path, verifies curl resolved it against the original loopback host, and checks the final body and effective URL.
# @timeout: 180
# @tags: usage, curl, http, redirect
# @client: curl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-curl-location-relative-redirect"
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
        if self.path == "/start":
            # Relative Location target — must be resolved by curl, not the server.
            self.send_response(302)
            self.send_header("Location", "deep/final")
            self.send_header("Content-Length", "0")
            self.end_headers()
            return
        if self.path == "/deep/final":
            body = b"relative-redirect-final\n"
            self.send_response(200)
            self.send_header("Content-Type", "text/plain")
            self.send_header("X-Final-Path", self.path)
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return
        self.send_response(404)
        self.send_header("Content-Length", "0")
        self.end_headers()

ThreadingHTTPServer(("127.0.0.1", int(os.environ["PORT"])), Handler).serve_forever()
PYCASE

port=$((29000 + RANDOM % 10000))
PORT="$port" python3 "$tmpdir/server.py" >"$tmpdir/server.log" 2>&1 &
pid=$!
for _ in $(seq 1 50); do
  if curl --noproxy '*' -fsS "http://127.0.0.1:$port/deep/final" >/dev/null 2>&1; then
    break
  fi
  sleep 0.1
done

curl --noproxy '*' -fsSL "http://127.0.0.1:$port/start" \
  -D "$tmpdir/headers" -w '%{url_effective}\n%{num_redirects}\n' \
  -o "$tmpdir/body" >"$tmpdir/meta"

validator_assert_contains "$tmpdir/body" 'relative-redirect-final'
validator_assert_contains "$tmpdir/headers" '302'
validator_assert_contains "$tmpdir/headers" 'Location: deep/final'
validator_assert_contains "$tmpdir/headers" 'X-Final-Path: /deep/final'
validator_assert_contains "$tmpdir/meta" "http://127.0.0.1:$port/deep/final"
grep -Fxq '1' "$tmpdir/meta" || {
  printf 'expected num_redirects=1 in meta\n' >&2
  cat "$tmpdir/meta" >&2
  exit 1
}

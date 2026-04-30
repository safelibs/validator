#!/usr/bin/env bash
# @testcase: usage-curl-writeout-ssl-verify-result-plain
# @title: curl -w %{ssl_verify_result} on plain HTTP returns 0
# @description: Requests plain HTTP from a loopback server and asserts curl -w '%{ssl_verify_result}' prints 0 because no TLS handshake happened.
# @timeout: 180
# @tags: usage, curl, http, writeout
# @client: curl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-curl-writeout-ssl-verify-result-plain"
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
        body = b"plain-http\n"
        self.send_response(200)
        self.send_header("Content-Type", "text/plain")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

ThreadingHTTPServer(("127.0.0.1", int(os.environ["PORT"])), Handler).serve_forever()
PYCASE

port=$((29000 + RANDOM % 10000))
PORT="$port" python3 "$tmpdir/server.py" >"$tmpdir/server.log" 2>&1 &
pid=$!
for _ in $(seq 1 50); do
  if curl --noproxy '*' -fsS "http://127.0.0.1:$port/" >/dev/null 2>&1; then
    break
  fi
  sleep 0.1
done

curl --noproxy '*' -fsS -o "$tmpdir/body" -w 'ssl_verify_result=%{ssl_verify_result}\n' "http://127.0.0.1:$port/" >"$tmpdir/out"
validator_assert_contains "$tmpdir/body" 'plain-http'
expected=$(printf 'ssl_verify_result=0\n')
actual=$(cat "$tmpdir/out")
if [[ "$actual" != "$expected" ]]; then
  printf 'expected %q got %q\n' "$expected" "$actual" >&2
  exit 1
fi

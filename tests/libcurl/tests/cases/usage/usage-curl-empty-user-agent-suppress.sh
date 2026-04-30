#!/usr/bin/env bash
# @testcase: usage-curl-empty-user-agent-suppress
# @title: curl -H "User-Agent:" suppresses the User-Agent header
# @description: Uses the curl -H "Header:" no-value syntax to remove the User-Agent header entirely, and verifies the loopback server reports the User-Agent as missing while a 200 status is still returned.
# @timeout: 180
# @tags: usage, curl, http, headers
# @client: curl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-curl-empty-user-agent-suppress"
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

    def _send(self, status, body=b""):
        self.send_response(status)
        self.send_header("Content-Type", "text/plain")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        ua = self.headers.get("User-Agent")
        marker = "ua=missing" if ua is None else "ua=" + ua
        self._send(200, (marker + "\n").encode())

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

http_code=$(curl --noproxy '*' -sS \
  -H 'User-Agent:' \
  -o "$tmpdir/out" -w '%{http_code}' \
  "http://127.0.0.1:$port/echo")

[[ "$http_code" == "200" ]] || {
  printf 'expected http_code 200, got %s\n' "$http_code" >&2
  exit 1
}

validator_assert_contains "$tmpdir/out" 'ua=missing'

# Sanity check: a normal request with curl's default UA reports a non-empty value.
curl --noproxy '*' -fsS "http://127.0.0.1:$port/echo" >"$tmpdir/default"
grep -q '^ua=curl/' "$tmpdir/default" || {
  printf 'expected default UA to start with curl/, got: %s\n' "$(cat "$tmpdir/default")" >&2
  exit 1
}

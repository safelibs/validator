#!/usr/bin/env bash
# @testcase: usage-curl-cookie-send-and-jar-save
# @title: curl -b cookie send combined with --cookie-jar save
# @description: Sends an inline cookie with -b in one call and saves a Set-Cookie response into a jar with --cookie-jar in another, asserting both the echoed Cookie header and the persisted jar entry.
# @timeout: 180
# @tags: usage, curl, http, cookies
# @client: curl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-curl-cookie-send-and-jar-save"
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

    def _send(self, status, body=b"", *, headers=None):
        self.send_response(status)
        self.send_header("Content-Type", "text/plain")
        if headers:
            for k, v in headers.items():
                self.send_header(k, v)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        if self.command != "HEAD":
            self.wfile.write(body)

    def do_GET(self):
        if self.path == "/probe":
            self._send(200, b"probe-ok\n")
        elif self.path == "/echo-cookie":
            body = ("cookie=" + self.headers.get("Cookie", "") + "\n").encode()
            self._send(200, body)
        elif self.path == "/set-cookie":
            self._send(200, b"set-ok\n", headers={"Set-Cookie": "jarmark=stored-by-curl; Path=/"})
        else:
            self._send(404, b"missing\n")

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

curl --noproxy '*' -fsS -b 'sent=from-flag' "http://127.0.0.1:$port/echo-cookie" >"$tmpdir/echo.out"
validator_assert_contains "$tmpdir/echo.out" 'cookie=sent=from-flag'

curl --noproxy '*' -fsS --cookie-jar "$tmpdir/jar.txt" "http://127.0.0.1:$port/set-cookie" >/dev/null
validator_assert_contains "$tmpdir/jar.txt" 'jarmark'
validator_assert_contains "$tmpdir/jar.txt" 'stored-by-curl'

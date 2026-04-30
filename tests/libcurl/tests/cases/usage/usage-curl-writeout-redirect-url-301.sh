#!/usr/bin/env bash
# @testcase: usage-curl-writeout-redirect-url-301
# @title: curl -w %{redirect_url} on 301 reports the Location target
# @description: Issues a request without -L against a custom server that returns 301 with a Location header and asserts curl -w '%{redirect_url}' prints the absolute redirect target.
# @timeout: 180
# @tags: usage, curl, http, writeout, redirect
# @client: curl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-curl-writeout-redirect-url-301"
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
        self.wfile.write(body)

    def do_GET(self):
        if self.path == "/probe":
            self._send(200, b"probe-ok\n")
        elif self.path == "/old":
            self._send(301, b"moved\n", headers={"Location": "/new-target"})
        elif self.path == "/new-target":
            self._send(200, b"new-body\n")
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

curl --noproxy '*' -sS -o "$tmpdir/body" -w 'redirect_url=%{redirect_url}\nhttp_code=%{http_code}\n' "http://127.0.0.1:$port/old" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" "redirect_url=http://127.0.0.1:$port/new-target"
validator_assert_contains "$tmpdir/out" 'http_code=301'

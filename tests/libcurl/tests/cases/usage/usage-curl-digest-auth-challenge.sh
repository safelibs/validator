#!/usr/bin/env bash
# @testcase: usage-curl-digest-auth-challenge
# @title: curl --digest auth completes challenge handshake
# @description: Connects to a custom server that returns a 401 with WWW-Authenticate Digest and asserts curl --digest replies with an Authorization Digest header that includes the expected username and realm.
# @timeout: 180
# @tags: usage, curl, http, auth
# @client: curl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-curl-digest-auth-challenge"
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

REALM = "validator-digest"
NONCE = "abc123validator"

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
            return
        auth = self.headers.get("Authorization", "")
        if auth.lower().startswith("digest "):
            self._send(200, ("auth-received\n" + auth + "\n").encode())
            return
        self._send(
            401,
            b"need digest\n",
            headers={"WWW-Authenticate": f'Digest realm="{REALM}", nonce="{NONCE}", qop="auth"'},
        )

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

curl --noproxy '*' -fsS --digest -u 'demo:secret' "http://127.0.0.1:$port/secure" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'auth-received'
validator_assert_contains "$tmpdir/out" 'Digest'
validator_assert_contains "$tmpdir/out" 'username="demo"'
validator_assert_contains "$tmpdir/out" 'realm="validator-digest"'

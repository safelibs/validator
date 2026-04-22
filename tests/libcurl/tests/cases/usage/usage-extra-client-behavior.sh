#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
tmpdir=$(mktemp -d)
trap 'jobs -pr | xargs -r kill 2>/dev/null || true; rm -rf "$tmpdir"' EXIT

start_server() {
  local port=$1
  cat >"$tmpdir/server.py" <<'PY'
from http.server import BaseHTTPRequestHandler, HTTPServer
import base64
import gzip
import sys

class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        return
    def _send(self, body, status=200, headers=None):
        self.send_response(status)
        for key, value in (headers or {}).items():
            self.send_header(key, value)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)
    def do_GET(self):
        if self.path.startswith("/query"):
            self._send(self.path.encode())
        elif self.path == "/auth":
            expected = "Basic " + base64.b64encode(b"user:pass").decode()
            self._send(b"auth ok\n" if self.headers.get("Authorization") == expected else b"auth missing\n", 200)
        elif self.path == "/set-cookie":
            self._send(b"cookie set\n", headers={"Set-Cookie": "validator=present; Path=/"})
        elif self.path == "/check-cookie":
            self._send((self.headers.get("Cookie", "missing") + "\n").encode())
        elif self.path == "/range":
            body = b"0123456789"
            if self.headers.get("Range") == "bytes=2-5":
                self._send(body[2:6], 206, {"Content-Range": "bytes 2-5/10"})
            else:
                self._send(body)
        elif self.path == "/gzip":
            self._send(gzip.compress(b"compressed body\n"), headers={"Content-Encoding": "gzip"})
        elif self.path == "/files/plain.txt":
            self._send(b"remote-name payload\n", headers={"Content-Type": "text/plain"})
        elif self.path == "/type":
            self._send(b"typed body\n", headers={"Content-Type": "text/plain"})
        else:
            self._send(b"missing\n", 404)
    def do_PUT(self):
        size = int(self.headers.get("Content-Length", "0"))
        self._send(b"put:" + self.rfile.read(size))
    def do_POST(self):
        size = int(self.headers.get("Content-Length", "0"))
        body = self.rfile.read(size)
        ctype = self.headers.get("Content-Type", "")
        if self.path == "/json":
            self._send((ctype + "\n").encode() + body)
        else:
            self._send(body)

HTTPServer(("127.0.0.1", int(sys.argv[1])), Handler).serve_forever()
PY
  python3 "$tmpdir/server.py" "$port" >"$tmpdir/server.log" 2>&1 &
  for _ in $(seq 1 40); do
    curl -fsS "http://127.0.0.1:$port/type" >/dev/null 2>&1 && return 0
    sleep 0.2
  done
  cat "$tmpdir/server.log" >&2
  return 1
}

port=$((18000 + RANDOM % 20000))
start_server "$port"
base="http://127.0.0.1:$port"

case "$case_id" in
  usage-curl-query-params)
    curl -fsS "$base/query?name=alpha&value=7" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'name=alpha'
    ;;
  usage-curl-basic-auth)
    curl -fsS -u user:pass "$base/auth" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'auth ok'
    ;;
  usage-curl-cookie-jar)
    curl -fsS -c "$tmpdir/cookies.txt" "$base/set-cookie" >/dev/null
    curl -fsS -b "$tmpdir/cookies.txt" "$base/check-cookie" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'validator=present'
    ;;
  usage-curl-range-request)
    curl -fsS -H 'Range: bytes=2-5' "$base/range" >"$tmpdir/out"
    grep -Fxq '2345' "$tmpdir/out"
    ;;
  usage-curl-compressed-response)
    curl -fsS --compressed "$base/gzip" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'compressed body'
    ;;
  usage-curl-put-upload)
    curl -fsS -X PUT --data-binary 'upload payload' "$base/put" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'put:upload payload'
    ;;
  usage-curl-form-post)
    curl -fsS -F 'field=value' "$base/form" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'name="field"'
    validator_assert_contains "$tmpdir/out" 'value'
    ;;
  usage-curl-http-code-variable)
    curl -fsS -o /dev/null -w 'code=%{http_code} type=%{content_type}\n' "$base/type" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'code=200'
    validator_assert_contains "$tmpdir/out" 'text/plain'
    ;;
  usage-curl-remote-name)
    (cd "$tmpdir" && curl -fsS -O "$base/files/plain.txt")
    validator_assert_contains "$tmpdir/plain.txt" 'remote-name payload'
    ;;
  usage-curl-json-header)
    curl -fsS -H 'Content-Type: application/json' --data '{"name":"alpha"}' "$base/json" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'application/json'
    validator_assert_contains "$tmpdir/out" '"name":"alpha"'
    ;;
  *)
    printf 'unknown libcurl extra usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac

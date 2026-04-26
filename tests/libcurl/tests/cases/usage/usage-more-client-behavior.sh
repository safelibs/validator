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
import sys

class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        return
    def _send(self, body, status=200, headers=None, head_only=False):
        self.send_response(status)
        for key, value in (headers or {}).items():
            self.send_header(key, value)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        if not head_only:
            self.wfile.write(body)
    def do_GET(self):
        if self.path == "/type":
            self._send(b"typed body\n", headers={"Content-Type": "text/plain"})
        elif self.path == "/files/plain.txt":
            self._send(b"remote-name payload\n", headers={"Content-Type": "text/plain"})
        elif self.path == "/referer":
            self._send((self.headers.get("Referer", "missing") + "\n").encode(), headers={"Content-Type": "text/plain"})
        elif self.path == "/check-cookie":
            self._send((self.headers.get("Cookie", "missing") + "\n").encode(), headers={"Content-Type": "text/plain"})
        elif self.path == "/content-disposition":
            self._send(b"named payload\n", headers={"Content-Type": "text/plain", "Content-Disposition": 'attachment; filename="named.txt"'})
        else:
            self._send(b"missing\n", status=404, headers={"Content-Type": "text/plain"})
    def do_HEAD(self):
        headers = {"Content-Type": "text/plain"}
        if self.path == "/head-echo":
            headers["X-Validator-Echo"] = self.headers.get("X-Validator", "missing")
            self._send(b"", headers=headers, head_only=True)
        else:
            self._send(b"typed body\n", headers=headers, head_only=True)
    def do_POST(self):
        size = int(self.headers.get("Content-Length", "0"))
        body = self.rfile.read(size)
        self._send(body, headers={"Content-Type": "text/plain"})
    def do_PUT(self):
        size = int(self.headers.get("Content-Length", "0"))
        body = self.rfile.read(size)
        self._send(b"put:" + body, headers={"Content-Type": "text/plain"})
    def do_DELETE(self):
        self._send(b"delete ok\n", headers={"Content-Type": "text/plain"})

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

port=$((20000 + RANDOM % 20000))
start_server "$port"
base="http://127.0.0.1:$port"

case "$case_id" in
  usage-curl-include-headers)
    curl -fsS -i "$base/type" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" '200 OK'
    validator_assert_contains "$tmpdir/out" 'typed body'
    ;;
  usage-curl-delete-request)
    curl -fsS -X DELETE "$base/delete" >"$tmpdir/out"
    grep -Fxq 'delete ok' "$tmpdir/out"
    ;;
  usage-curl-data-raw-post)
    curl -fsS --data-raw 'raw=alpha beta' "$base/post" >"$tmpdir/out"
    grep -Fxq 'raw=alpha beta' "$tmpdir/out"
    ;;
  usage-curl-next-multiple-urls)
    curl -fsS "$base/type" --next "$base/files/plain.txt" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'typed body'
    validator_assert_contains "$tmpdir/out" 'remote-name payload'
    ;;
  usage-curl-referer-header)
    curl -fsS -e 'https://example.invalid/source' "$base/referer" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'https://example.invalid/source'
    ;;
  usage-curl-upload-stdin)
    printf 'stdin payload\n' | curl -fsS --data-binary @- "$base/post" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'stdin payload'
    ;;
  usage-curl-head-header-echo)
    curl -fsSI -H 'X-Validator: head value' "$base/head-echo" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'X-Validator-Echo: head value'
    ;;
  usage-curl-remote-header-name)
    (cd "$tmpdir" && curl -fsS -OJ "$base/content-disposition")
    validator_assert_contains "$tmpdir/named.txt" 'named payload'
    ;;
  usage-curl-trace-ascii)
    curl -fsS --trace-ascii "$tmpdir/trace.log" "$base/type" -o /dev/null
    validator_assert_contains "$tmpdir/trace.log" 'GET /type HTTP'
    ;;
  usage-curl-inline-cookie)
    curl -fsS -b 'validator=inline' "$base/check-cookie" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'validator=inline'
    ;;
  *)
    printf 'unknown libcurl additional usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac

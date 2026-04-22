#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
tmpdir=$(mktemp -d)
trap 'jobs -pr | xargs -r kill 2>/dev/null || true; rm -rf "$tmpdir"' EXIT

start_static_server() {
  local port=$1
  mkdir -p "$tmpdir/www"
  printf 'downloaded through curl\n' >"$tmpdir/www/plain.txt"
  python3 -m http.server "$port" --bind 127.0.0.1 --directory "$tmpdir/www" >"$tmpdir/http.log" 2>&1 &
  for _ in $(seq 1 40); do
    curl -fsS "http://127.0.0.1:$port/plain.txt" >/dev/null 2>&1 && return 0
    sleep 0.25
  done
  cat "$tmpdir/http.log" >&2
  return 1
}

start_custom_server() {
  local port=$1
  cat >"$tmpdir/server.py" <<'PY'
from http.server import BaseHTTPRequestHandler, HTTPServer
import sys

class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        return
    def do_GET(self):
        if self.path == "/redirect":
            self.send_response(302)
            self.send_header("Location", "/plain.txt")
            self.end_headers()
            return
        body = b"custom header=" + self.headers.get("X-Validator", "missing").encode()
        if self.path == "/plain.txt":
            body = b"custom server body\n"
        self.send_response(200)
        self.send_header("Content-Type", "text/plain")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)
    def do_POST(self):
        size = int(self.headers.get("Content-Length", "0"))
        body = b"post:" + self.rfile.read(size)
        self.send_response(200)
        self.send_header("Content-Type", "text/plain")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

HTTPServer(("127.0.0.1", int(sys.argv[1])), Handler).serve_forever()
PY
  python3 "$tmpdir/server.py" "$port" >"$tmpdir/custom-http.log" 2>&1 &
  for _ in $(seq 1 40); do
    curl -fsS "http://127.0.0.1:$port/plain.txt" >/dev/null 2>&1 && return 0
    sleep 0.25
  done
  cat "$tmpdir/custom-http.log" >&2
  return 1
}

case "$case_id" in
  usage-curl-http-get)
    port=18081
    start_static_server "$port"
    curl -fsS "http://127.0.0.1:$port/plain.txt" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'downloaded through curl'
    ;;
  usage-curl-head-request)
    port=18082
    start_static_server "$port"
    curl -fsSI "http://127.0.0.1:$port/plain.txt" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" '200'
    ;;
  usage-curl-output-file)
    port=18083
    start_static_server "$port"
    curl -fsS -o "$tmpdir/download.txt" "http://127.0.0.1:$port/plain.txt"
    validator_assert_contains "$tmpdir/download.txt" 'downloaded through curl'
    ;;
  usage-curl-write-out)
    port=18084
    start_static_server "$port"
    curl -fsS -o /dev/null -w 'code=%{http_code} size=%{size_download}\n' "http://127.0.0.1:$port/plain.txt" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'code=200'
    ;;
  usage-curl-fail-status)
    port=18085
    start_static_server "$port"
    if curl -fsS "http://127.0.0.1:$port/missing.txt" >"$tmpdir/out" 2>"$tmpdir/err"; then
      printf 'curl --fail unexpectedly accepted missing path\n' >&2
      exit 1
    fi
    validator_assert_contains "$tmpdir/err" '404'
    ;;
  usage-curl-file-url)
    printf 'file url payload\n' >"$tmpdir/local.txt"
    curl -fsS "file://$tmpdir/local.txt" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'file url payload'
    ;;
  usage-curl-post-echo)
    port=18086
    start_custom_server "$port"
    curl -fsS -X POST --data 'payload=validator' "http://127.0.0.1:$port/post" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'post:payload=validator'
    ;;
  usage-curl-redirect)
    port=18087
    start_custom_server "$port"
    curl -fsSL "http://127.0.0.1:$port/redirect" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'custom server body'
    ;;
  usage-curl-custom-header)
    port=18088
    start_custom_server "$port"
    curl -fsS -H 'X-Validator: present' "http://127.0.0.1:$port/header" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'custom header=present'
    ;;
  usage-curl-version-features)
    curl --version >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'HTTP'
    ;;
  *)
    printf 'unknown libcurl usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac

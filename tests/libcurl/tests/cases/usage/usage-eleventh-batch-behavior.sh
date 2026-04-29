#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
tmpdir=$(mktemp -d)
trap 'jobs -pr | xargs -r kill 2>/dev/null || true; rm -rf "$tmpdir"' EXIT

start_server() {
  local port=$1
  cat >"$tmpdir/server.py" <<'PYCASE'
from http.server import BaseHTTPRequestHandler, HTTPServer
import base64
import gzip
import sys

class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        return
    def send_body(self, body, extra=None):
        self.send_response(200)
        self.send_header('Content-Type', 'text/plain')
        self.send_header('Content-Length', str(len(body)))
        if extra:
            for key, value in extra.items():
                self.send_header(key, value)
        self.end_headers()
        self.wfile.write(body)
    def do_GET(self):
        if self.path.startswith('/ua'):
            self.send_body(('ua=' + self.headers.get('User-Agent', '')).encode())
        elif self.path.startswith('/cookie'):
            self.send_body(('cookie=' + self.headers.get('Cookie', '')).encode())
        elif self.path.startswith('/auth'):
            self.send_body(('auth=' + self.headers.get('Authorization', '')).encode())
        elif self.path.startswith('/gzip'):
            body = gzip.compress(b'compressed response payload\n')
            self.send_response(200)
            self.send_header('Content-Type', 'text/plain')
            self.send_header('Content-Encoding', 'gzip')
            self.send_header('Content-Length', str(len(body)))
            self.end_headers()
            self.wfile.write(body)
        elif self.path.startswith('/host'):
            self.send_body(('host=' + self.headers.get('Host', '')).encode())
        elif self.path.startswith('/query'):
            self.send_body(('path=' + self.path).encode())
        elif self.path.startswith('/etag'):
            self.send_body(b'etag body\n', {'ETag': '"validator-etag"'})
        elif self.path.startswith('/download'):
            self.send_body(b'named download\n', {'Content-Disposition': 'attachment; filename="named.txt"'})
        else:
            self.send_body(b'ok\n')
    def do_PUT(self):
        size = int(self.headers.get('Content-Length', '0'))
        self.send_body(b'put:' + self.rfile.read(size))

HTTPServer(('127.0.0.1', int(sys.argv[1])), Handler).serve_forever()
PYCASE
  python3 "$tmpdir/server.py" "$port" >"$tmpdir/server.log" 2>&1 &
  for _ in $(seq 1 40); do
    curl --noproxy '*' -fsS "http://127.0.0.1:$port/" >/dev/null 2>&1 && return 0
    sleep 0.2
  done
  cat "$tmpdir/server.log" >&2
  return 1
}

port=$((19000 + RANDOM % 2000))
start_server "$port"
base="http://127.0.0.1:$port"

case "$case_id" in
  usage-curl-put-echo-batch11)
    curl --noproxy '*' -fsS -X PUT --data 'payload=put' "$base/put" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'put:payload=put'
    ;;
  usage-curl-user-agent-header-batch11)
    curl --noproxy '*' -fsS -A 'validator-agent/1' "$base/ua" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'validator-agent/1'
    ;;
  usage-curl-cookie-header-batch11)
    curl --noproxy '*' -fsS -b 'session=abc123' "$base/cookie" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'session=abc123'
    ;;
  usage-curl-basic-auth-header-batch11)
    curl --noproxy '*' -fsS -u 'user:pass' "$base/auth" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'Basic'
    ;;
  usage-curl-compressed-gzip-response-batch11)
    curl --noproxy '*' -fsS --compressed "$base/gzip" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'compressed response payload'
    ;;
  usage-curl-resolve-loopback-host-batch11)
    curl --noproxy '*' -fsS --resolve "validator.invalid:$port:127.0.0.1" "http://validator.invalid:$port/host" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" "host=validator.invalid:$port"
    ;;
  usage-curl-query-data-urlencode-batch11)
    curl --noproxy '*' -fsS --get --data-urlencode 'q=alpha beta' "$base/query" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'q=alpha+beta'
    ;;
  usage-curl-etag-header-output-batch11)
    curl --noproxy '*' -fsS -D "$tmpdir/headers" "$base/etag" -o "$tmpdir/body"
    validator_assert_contains "$tmpdir/headers" 'ETag: "validator-etag"'
    ;;
  usage-curl-content-disposition-remote-name-batch11)
    (cd "$tmpdir" && curl --noproxy '*' -fsS -OJ "$base/download")
    validator_assert_contains "$tmpdir/named.txt" 'named download'
    ;;
  usage-curl-max-time-success-batch11)
    curl --noproxy '*' -fsS --max-time 5 "$base/" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'ok'
    ;;
  *)
    printf 'unknown libcurl eleventh-batch usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac

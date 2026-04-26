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
        self.send_header('Content-Length', str(len(body)))
        self.end_headers()
        if not head_only:
            self.wfile.write(body)
    def do_GET(self):
        if self.path.startswith('/query'):
            self._send(self.path.encode(), headers={'Content-Type': 'text/plain'})
        elif self.path == '/type':
            self._send(b'typed body\n', headers={'Content-Type': 'text/plain'})
        elif self.path == '/files/plain.txt':
            self._send(b'remote-name payload\n', headers={'Content-Type': 'text/plain'})
        elif self.path == '/accept':
            self._send((self.headers.get('Accept', 'missing') + '\n').encode(), headers={'Content-Type': 'text/plain'})
        elif self.path == '/protocol':
            self._send((self.request_version + '\n').encode(), headers={'Content-Type': 'text/plain'})
        elif self.path == '/redirect':
            self._send(b'', status=302, headers={'Location': '/type'})
        else:
            self._send(b'missing\n', status=404, headers={'Content-Type': 'text/plain'})
    def do_POST(self):
        size = int(self.headers.get('Content-Length', '0'))
        body = self.rfile.read(size)
        self._send(body, headers={'Content-Type': 'text/plain'})
    def do_PUT(self):
        size = int(self.headers.get('Content-Length', '0'))
        body = self.rfile.read(size)
        self._send(b'put:' + body, headers={'Content-Type': 'text/plain'})
    def do_DELETE(self):
        self._send(b'delete ok\n', headers={'Content-Type': 'text/plain'})

HTTPServer(('127.0.0.1', int(sys.argv[1])), Handler).serve_forever()
PY
  python3 "$tmpdir/server.py" "$port" >"$tmpdir/server.log" 2>&1 &
  for _ in $(seq 1 40); do
    curl -fsS "http://127.0.0.1:$port/type" >/dev/null 2>&1 && return 0
    sleep 0.2
  done
  cat "$tmpdir/server.log" >&2
  return 1
}

port=$((32000 + RANDOM % 6000))
start_server "$port"
base="http://127.0.0.1:$port"

case "$case_id" in
  usage-curl-get-urlencode-query)
    curl -fsS -G --data-urlencode 'name=alpha beta' "$base/query" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'name=alpha'
    validator_assert_contains "$tmpdir/out" 'beta'
    ;;
  usage-curl-upload-file)
    printf 'upload file payload\n' >"$tmpdir/input.txt"
    curl -fsS -T "$tmpdir/input.txt" "$base/upload" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'put:upload file payload'
    ;;
  usage-curl-create-dirs-output)
    curl -fsS --create-dirs -o "$tmpdir/a/b/out.txt" "$base/files/plain.txt"
    validator_assert_contains "$tmpdir/a/b/out.txt" 'remote-name payload'
    ;;
  usage-curl-effective-url-writeout)
    curl -fsSL -o /dev/null -w 'url=%{url_effective}\n' "$base/redirect" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" '/type'
    ;;
  usage-curl-redirect-count-writeout)
    curl -fsSL -o /dev/null -w 'redirects=%{num_redirects}\n' "$base/redirect" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'redirects=1'
    ;;
  usage-curl-post-empty-body)
    curl -fsS --data '' "$base/post" >"$tmpdir/out"
    test "$(wc -c <"$tmpdir/out")" -eq 0
    ;;
  usage-curl-accept-header)
    curl -fsS -H 'Accept: application/json' "$base/accept" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'application/json'
    ;;
  usage-curl-http1-1-request)
    curl -fsS --http1.1 "$base/protocol" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'HTTP/1.1'
    ;;
  usage-curl-delete-include-headers)
    curl -fsS -i -X DELETE "$base/delete" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" '200 OK'
    validator_assert_contains "$tmpdir/out" 'delete ok'
    ;;
  usage-curl-data-urlencode-plus)
    curl -fsS --data-urlencode 'field=a+b c' "$base/post" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'field='
    validator_assert_contains "$tmpdir/out" '%2B'
    ;;
  *)
    printf 'unknown libcurl even-more usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac

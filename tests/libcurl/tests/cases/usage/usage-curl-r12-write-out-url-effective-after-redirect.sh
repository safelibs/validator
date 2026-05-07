#!/usr/bin/env bash
# @testcase: usage-curl-r12-write-out-url-effective-after-redirect
# @title: curl -L -w %{url_effective} reports the redirected target URL after Location follow
# @description: Hosts a loopback handler that returns 301 Location -> /final and serves /final with HTTP 200, runs curl -L with -w '%{url_effective}', and asserts the captured token is the absolute URL of /final on the test port.
# @timeout: 180
# @tags: usage, curl, http, redirect, write-out
# @client: curl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
pid=""
cleanup() {
    if [[ -n "$pid" ]]; then kill "$pid" 2>/dev/null || true; wait "$pid" 2>/dev/null || true; fi
    rm -rf "$tmpdir"
}
trap cleanup EXIT

cat >"$tmpdir/server.py" <<'PY'
from http.server import BaseHTTPRequestHandler, HTTPServer
import os
class H(BaseHTTPRequestHandler):
    def log_message(self, *a, **k): pass
    def do_GET(self):
        if self.path == '/start':
            self.send_response(301)
            self.send_header('Location', '/final')
            self.send_header('Content-Length', '0')
            self.end_headers()
        elif self.path == '/final':
            body = b'final body\n'
            self.send_response(200)
            self.send_header('Content-Type', 'text/plain')
            self.send_header('Content-Length', str(len(body)))
            self.end_headers()
            self.wfile.write(body)
        else:
            self.send_response(404)
            self.send_header('Content-Length', '0')
            self.end_headers()
HTTPServer(('127.0.0.1', int(os.environ['PORT'])), H).serve_forever()
PY

port=$((23000 + RANDOM % 19000))
PORT="$port" python3 "$tmpdir/server.py" >/dev/null 2>&1 &
pid=$!
for _ in $(seq 1 60); do
    curl --noproxy '*' -fsS --max-time 2 -o /dev/null "http://127.0.0.1:$port/final" 2>/dev/null && break
    sleep 0.1
done

got=$(curl --noproxy '*' -sS --max-time 5 -L \
            -o "$tmpdir/body" -w '%{url_effective}' \
            "http://127.0.0.1:$port/start")
expected="http://127.0.0.1:$port/final"
[[ "$got" == "$expected" ]] || {
    printf 'expected url_effective %q, got %q\n' "$expected" "$got" >&2
    exit 1
}
validator_assert_contains "$tmpdir/body" 'final body'

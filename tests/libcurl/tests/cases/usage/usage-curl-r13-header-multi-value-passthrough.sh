#!/usr/bin/env bash
# @testcase: usage-curl-r13-header-multi-value-passthrough
# @title: curl --header passes multiple custom request headers through to the server
# @description: Hosts a loopback server that echoes selected request headers, sends a request with two -H flags carrying distinct X-Marker-A and X-Marker-B values, and asserts both header values are recorded verbatim in the server's response body.
# @timeout: 180
# @tags: usage, curl, http, header
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
        a = self.headers.get('X-Marker-A', 'missing')
        b = self.headers.get('X-Marker-B', 'missing')
        body = ('A=' + a + '\nB=' + b + '\n').encode()
        self.send_response(200)
        self.send_header('Content-Type', 'text/plain')
        self.send_header('Content-Length', str(len(body)))
        self.end_headers()
        self.wfile.write(body)
HTTPServer(('127.0.0.1', int(os.environ['PORT'])), H).serve_forever()
PY

port=$((23000 + RANDOM % 19000))
PORT="$port" python3 "$tmpdir/server.py" >/dev/null 2>&1 &
pid=$!
for _ in $(seq 1 60); do
    curl --noproxy '*' -fsS --max-time 2 -o /dev/null "http://127.0.0.1:$port/" 2>/dev/null && break
    sleep 0.1
done

curl --noproxy '*' -fsS --max-time 5 \
    --header 'X-Marker-A: alpha-r13' \
    --header 'X-Marker-B: bravo-r13' \
    -o "$tmpdir/out" "http://127.0.0.1:$port/echo"

validator_assert_contains "$tmpdir/out" 'A=alpha-r13'
validator_assert_contains "$tmpdir/out" 'B=bravo-r13'

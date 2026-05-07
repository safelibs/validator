#!/usr/bin/env bash
# @testcase: usage-curl-r13-request-flag-overrides-method
# @title: curl --request PROPFIND sends an arbitrary HTTP method to the server
# @description: Posts to a loopback server that echoes self.command and asserts curl --request PROPFIND -X via the long form sends the literal PROPFIND verb in the request line. Confirms --request overrides the default GET.
# @timeout: 180
# @tags: usage, curl, http, request
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
        self._send()
    def _send(self):
        body = ('method=' + self.command + '\n').encode()
        self.send_response(200)
        self.send_header('Content-Type', 'text/plain')
        self.send_header('Content-Length', str(len(body)))
        self.end_headers()
        self.wfile.write(body)
    # Custom method handler.
    def do_PROPFIND(self):
        self._send()
HTTPServer(('127.0.0.1', int(os.environ['PORT'])), H).serve_forever()
PY

port=$((23000 + RANDOM % 19000))
PORT="$port" python3 "$tmpdir/server.py" >/dev/null 2>&1 &
pid=$!
for _ in $(seq 1 60); do
    curl --noproxy '*' -fsS --max-time 2 -o /dev/null "http://127.0.0.1:$port/" 2>/dev/null && break
    sleep 0.1
done

curl --noproxy '*' -fsS --max-time 5 --request PROPFIND \
    -o "$tmpdir/out" "http://127.0.0.1:$port/resource"

validator_assert_contains "$tmpdir/out" 'method=PROPFIND'

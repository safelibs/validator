#!/usr/bin/env bash
# @testcase: usage-curl-r13-user-agent-explicit-string
# @title: curl --user-agent sets the User-Agent header to the supplied literal string
# @description: Issues a request to a loopback server that echoes the User-Agent header back in the response body and asserts curl --user-agent "validator-r13/1.0" results in the exact User-Agent string being recorded server-side.
# @timeout: 180
# @tags: usage, curl, http, user-agent
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
        ua = self.headers.get('User-Agent', 'missing')
        body = ('ua=' + ua + '\n').encode()
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
    --user-agent 'validator-r13/1.0' \
    -o "$tmpdir/out" "http://127.0.0.1:$port/probe"

validator_assert_contains "$tmpdir/out" 'ua=validator-r13/1.0'

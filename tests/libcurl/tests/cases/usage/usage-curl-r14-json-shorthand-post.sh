#!/usr/bin/env bash
# @testcase: usage-curl-r14-json-shorthand-post
# @title: curl --json sends a POST with application/json content-type and accept headers
# @description: Issues curl --json '{"a":1}' against a python POST echo handler and asserts the recorded request was a POST whose Content-Type and Accept headers are both application/json (the curl 7.82+ --json shorthand) and whose body equals the supplied JSON literal.
# @timeout: 180
# @tags: usage, curl, http, post, json
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
    def do_POST(self):
        n = int(self.headers.get('Content-Length', '0') or '0')
        body = self.rfile.read(n) if n else b''
        ct = self.headers.get('Content-Type', '')
        ac = self.headers.get('Accept', '')
        out = ('ct=' + ct + '\nac=' + ac + '\nbody=' + body.decode('utf-8', errors='replace') + '\n').encode()
        self.send_response(200)
        self.send_header('Content-Type', 'text/plain')
        self.send_header('Content-Length', str(len(out)))
        self.end_headers()
        self.wfile.write(out)
HTTPServer(('127.0.0.1', int(os.environ['PORT'])), H).serve_forever()
PY

port=$((23000 + RANDOM % 19000))
PORT="$port" python3 "$tmpdir/server.py" >/dev/null 2>&1 &
pid=$!
for _ in $(seq 1 60); do
    curl --noproxy '*' -sS --max-time 2 -o /dev/null -X POST -d '' "http://127.0.0.1:$port/" 2>/dev/null && break
    sleep 0.1
done

curl --noproxy '*' -fsS --max-time 5 \
    --json '{"r14":"json-shorthand","ok":true}' \
    -o "$tmpdir/out" "http://127.0.0.1:$port/echo"

validator_assert_contains "$tmpdir/out" 'ct=application/json'
validator_assert_contains "$tmpdir/out" 'ac=application/json'
validator_assert_contains "$tmpdir/out" 'body={"r14":"json-shorthand","ok":true}'

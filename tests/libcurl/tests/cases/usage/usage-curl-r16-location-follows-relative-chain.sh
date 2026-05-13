#!/usr/bin/env bash
# @testcase: usage-curl-r16-location-follows-relative-chain
# @title: curl -L follows a single 302 redirect to the destination body
# @description: Stands up a tiny http.server that replies with a 302 Location: /target.txt to the root path and serves a fixed body at /target.txt. Asserts curl -L returns the target body, locking in basic --location single-hop redirect handling.
# @timeout: 60
# @tags: usage, curl, location, redirect
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
import http.server, sys
class H(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/':
            self.send_response(302)
            self.send_header('Location','/target.txt')
            self.send_header('Content-Length','0')
            self.end_headers()
            return
        if self.path == '/target.txt':
            body = b'r16-location-target-body\n'
            self.send_response(200)
            self.send_header('Content-Type','text/plain')
            self.send_header('Content-Length', str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return
        self.send_response(404); self.send_header('Content-Length','0'); self.end_headers()
    def log_message(self, *a, **k): pass
http.server.HTTPServer(('127.0.0.1', int(sys.argv[1])), H).serve_forever()
PY

port=$((23500 + RANDOM % 19000))
python3 "$tmpdir/server.py" "$port" >/dev/null 2>&1 &
pid=$!
for _ in $(seq 1 60); do
    curl --noproxy '*' -fsS --max-time 2 -o /dev/null "http://127.0.0.1:$port/target.txt" 2>/dev/null && break
    sleep 0.1
done

curl --noproxy '*' -fsSL --max-time 5 "http://127.0.0.1:$port/" -o "$tmpdir/got.txt"

validator_assert_contains "$tmpdir/got.txt" 'r16-location-target-body'

#!/usr/bin/env bash
# @testcase: usage-curl-r18-follow-redirect-l-flag
# @title: curl -L follows a 302 redirect and returns the final body
# @description: Stands up a python loopback http.server that responds to /go with a 302 Location pointing at /final and to /final with the body "destination", then issues curl -L against /go and asserts the captured body equals "destination" — locking in -L redirect-following behavior.
# @timeout: 90
# @tags: usage, curl, redirect, follow, r18
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
PORT=int(sys.argv[1])
class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/go':
            self.send_response(302)
            self.send_header('Location', f'http://127.0.0.1:{PORT}/final')
            self.send_header('Content-Length','0')
            self.end_headers()
        elif self.path == '/final':
            body=b'destination'
            self.send_response(200); self.send_header('Content-Type','text/plain'); self.send_header('Content-Length', str(len(body))); self.end_headers(); self.wfile.write(body)
        else:
            body=b'ok'; self.send_response(200); self.send_header('Content-Length', str(len(body))); self.end_headers(); self.wfile.write(body)
    def log_message(self, *a, **k): pass
http.server.HTTPServer(('127.0.0.1', PORT), Handler).serve_forever()
PY

port=$((30300 + RANDOM % 18000))
python3 "$tmpdir/server.py" "$port" >/dev/null 2>&1 &
pid=$!
ready=0
for _ in $(seq 1 60); do
    if curl --noproxy '*' -fsS --max-time 2 -o /dev/null "http://127.0.0.1:$port/.ping" 2>/dev/null; then
        ready=1; break
    fi
    sleep 0.1
done
[[ "$ready" -eq 1 ]] || { printf 'server never became ready\n' >&2; exit 1; }

curl --noproxy '*' -fsSL --max-time 5 \
    "http://127.0.0.1:$port/go" -o "$tmpdir/got.txt"

got=$(cat "$tmpdir/got.txt")
[[ "$got" == "destination" ]] || {
    printf 'expected "destination", got %q\n' "$got" >&2
    exit 1
}

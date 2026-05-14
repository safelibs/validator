#!/usr/bin/env bash
# @testcase: usage-curl-r17-cookie-flag-echo
# @title: curl --cookie key=value reaches the loopback server's Cookie header
# @description: Stands up a python http.server that echoes the Cookie request header into the response body, asserts the server is reachable, then issues curl --cookie 'session=tokenR17' and confirms the response body contains "session=tokenR17".
# @timeout: 90
# @tags: usage, curl, cookie
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
class Echo(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        c = self.headers.get('Cookie', '<absent>')
        body = c.encode('utf-8')
        self.send_response(200)
        self.send_header('Content-Type', 'text/plain')
        self.send_header('Content-Length', str(len(body)))
        self.end_headers()
        self.wfile.write(body)
    def log_message(self, *a, **k):
        pass
http.server.HTTPServer(('127.0.0.1', int(sys.argv[1])), Echo).serve_forever()
PY

port=$((24200 + RANDOM % 18000))
python3 "$tmpdir/server.py" "$port" >/dev/null 2>&1 &
pid=$!
ready=0
for _ in $(seq 1 60); do
    if curl --noproxy '*' -fsS --max-time 2 -o /dev/null "http://127.0.0.1:$port/.ping" 2>/dev/null; then
        ready=1
        break
    fi
    sleep 0.1
done
[[ "$ready" -eq 1 ]] || { printf 'server never became ready\n' >&2; exit 1; }

curl --noproxy '*' -fsS --max-time 5 \
    --cookie 'session=tokenR17' \
    "http://127.0.0.1:$port/echo" -o "$tmpdir/got.txt"

validator_assert_contains "$tmpdir/got.txt" 'session=tokenR17'

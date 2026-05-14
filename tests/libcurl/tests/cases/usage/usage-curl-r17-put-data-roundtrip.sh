#!/usr/bin/env bash
# @testcase: usage-curl-r17-put-data-roundtrip
# @title: curl -X PUT --data sends a body that the loopback PUT handler echoes back
# @description: Stands up a python http.server with a do_PUT handler that echoes the request body, asserts the server is reachable, then runs curl -X PUT --data 'k=v' and confirms the response body equals "k=v".
# @timeout: 90
# @tags: usage, curl, put
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
        body = b'ready'
        self.send_response(200)
        self.send_header('Content-Type', 'text/plain')
        self.send_header('Content-Length', str(len(body)))
        self.end_headers()
        self.wfile.write(body)
    def do_PUT(self):
        n = int(self.headers.get('Content-Length', '0'))
        body = self.rfile.read(n)
        self.send_response(200)
        self.send_header('Content-Type', 'text/plain')
        self.send_header('Content-Length', str(len(body)))
        self.end_headers()
        self.wfile.write(body)
    def log_message(self, *a, **k):
        pass
http.server.HTTPServer(('127.0.0.1', int(sys.argv[1])), Echo).serve_forever()
PY

port=$((24400 + RANDOM % 18000))
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
    -X PUT --data 'k=v' \
    "http://127.0.0.1:$port/echo" -o "$tmpdir/got.txt"

got=$(cat "$tmpdir/got.txt")
[[ "$got" == "k=v" ]] || {
    printf 'expected PUT echo "k=v", got %q\n' "$got" >&2
    exit 1
}

#!/usr/bin/env bash
# @testcase: usage-curl-r18-data-urlencode-percent-escapes
# @title: curl --data-urlencode percent-escapes a reserved character before sending
# @description: Stands up a python loopback http.server that echoes the POST body verbatim, then issues curl with --data-urlencode 'k=a b&c' and asserts the echoed body equals "k=a%20b%26c" — locking in curl's client-side percent-encoding of space and ampersand.
# @timeout: 90
# @tags: usage, curl, data-urlencode, r18
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
        self.send_response(200); self.send_header('Content-Length','2'); self.end_headers(); self.wfile.write(b'ok')
    def do_POST(self):
        n = int(self.headers.get('Content-Length','0'))
        b = self.rfile.read(n)
        self.send_response(200); self.send_header('Content-Type','text/plain'); self.send_header('Content-Length', str(len(b))); self.end_headers(); self.wfile.write(b)
    def log_message(self, *a, **k): pass
http.server.HTTPServer(('127.0.0.1', int(sys.argv[1])), Echo).serve_forever()
PY

port=$((30100 + RANDOM % 18000))
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

curl --noproxy '*' -fsS --max-time 5 \
    --data-urlencode 'k=a b&c' \
    "http://127.0.0.1:$port/echo" -o "$tmpdir/got.txt"

got=$(cat "$tmpdir/got.txt")
want='k=a%20b%26c'
[[ "$got" == "$want" ]] || {
    printf 'urlencode mismatch: want=%q got=%q\n' "$want" "$got" >&2
    exit 1
}

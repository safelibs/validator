#!/usr/bin/env bash
# @testcase: usage-curl-r20-head-content-length-numeric
# @title: curl -I receives a numeric Content-Length header from loopback
# @description: Stands up a python loopback http.server that returns a fixed 11-byte body with Content-Length set, then issues curl -I and asserts the response headers contain a "Content-Length: 11" line - locking in HEAD-request header propagation.
# @timeout: 90
# @tags: usage, curl, head, content-length, r20
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
BODY=b'hello world'
class H(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200); self.send_header('Content-Length', str(len(BODY))); self.end_headers(); self.wfile.write(BODY)
    def do_HEAD(self):
        self.send_response(200); self.send_header('Content-Length', str(len(BODY))); self.end_headers()
    def log_message(self,*a,**k): pass
http.server.HTTPServer(('127.0.0.1', int(sys.argv[1])), H).serve_forever()
PY

port=$((41100 + RANDOM % 18000))
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

curl --noproxy '*' -sS --max-time 5 -I "http://127.0.0.1:$port/" -o "$tmpdir/h.txt"
LC_ALL=C grep -Eiq '^Content-Length: 11[[:space:]]*$' "$tmpdir/h.txt" || {
    echo 'expected Content-Length: 11 in headers' >&2
    cat "$tmpdir/h.txt" >&2
    exit 1
}

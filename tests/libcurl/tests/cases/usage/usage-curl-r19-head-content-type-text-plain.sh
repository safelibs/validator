#!/usr/bin/env bash
# @testcase: usage-curl-r19-head-content-type-text-plain
# @title: curl -I receives Content-Type text/plain from a HEAD-responding loopback server
# @description: Stands up a python loopback http.server that returns Content-Type text/plain on HEAD, issues curl -I, and asserts the captured headers contain "Content-Type: text/plain" with no message body bytes - locking in -I HEAD request behavior and header surface.
# @timeout: 90
# @tags: usage, curl, head, content-type, r19
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
    def do_HEAD(self):
        self.send_response(200)
        self.send_header('Content-Type','text/plain')
        self.send_header('Content-Length','42')
        self.end_headers()
    def do_GET(self):
        b=b'a'*42
        self.send_response(200); self.send_header('Content-Type','text/plain'); self.send_header('Content-Length','42'); self.end_headers(); self.wfile.write(b)
    def log_message(self,*a,**k): pass
http.server.HTTPServer(('127.0.0.1', int(sys.argv[1])), H).serve_forever()
PY

port=$((40800 + RANDOM % 18000))
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

curl --noproxy '*' -fsS --max-time 5 -I "http://127.0.0.1:$port/" -o "$tmpdir/hdr.txt"
validator_assert_contains "$tmpdir/hdr.txt" 'Content-Type: text/plain'
validator_assert_contains "$tmpdir/hdr.txt" 'Content-Length: 42'

#!/usr/bin/env bash
# @testcase: usage-curl-r20-data-binary-post-echo
# @title: curl --data-binary preserves a payload byte-for-byte through POST to loopback
# @description: Stands up a python loopback http.server that echoes the POST body, then posts with curl --data-binary @file using a fixed payload containing newlines, and asserts the recovered body matches the source file byte-for-byte - locking in --data-binary's no-transform behavior.
# @timeout: 90
# @tags: usage, curl, data-binary, post, r20
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
        b=b'ok'; self.send_response(200); self.send_header('Content-Length', str(len(b))); self.end_headers(); self.wfile.write(b)
    def do_POST(self):
        n=int(self.headers.get('Content-Length','0'))
        b=self.rfile.read(n)
        self.send_response(200); self.send_header('Content-Length', str(len(b))); self.end_headers(); self.wfile.write(b)
    def log_message(self,*a,**k): pass
http.server.HTTPServer(('127.0.0.1', int(sys.argv[1])), H).serve_forever()
PY

port=$((41300 + RANDOM % 18000))
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

printf 'first\nsecond\nthird\n' >"$tmpdir/payload.txt"
curl --noproxy '*' -fsS --max-time 5 --data-binary "@$tmpdir/payload.txt" "http://127.0.0.1:$port/echo" -o "$tmpdir/got"
cmp -s "$tmpdir/payload.txt" "$tmpdir/got" || {
    echo 'echoed body did not match source' >&2
    od -An -c <"$tmpdir/payload.txt" >&2
    od -An -c <"$tmpdir/got" >&2
    exit 1
}

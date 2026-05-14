#!/usr/bin/env bash
# @testcase: usage-curl-r18-form-multipart-field
# @title: curl --form sends a multipart/form-data POST whose body carries the field name and value
# @description: Stands up a python loopback http.server that echoes the POST body, then issues curl --form 'greeting=hi-there' and asserts the recovered body contains the multipart boundary marker plus both the field name "greeting" and the field value "hi-there".
# @timeout: 90
# @tags: usage, curl, form, multipart, r18
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
        b=b'ok'; self.send_response(200); self.send_header('Content-Length', str(len(b))); self.end_headers(); self.wfile.write(b)
    def do_POST(self):
        n = int(self.headers.get('Content-Length','0'))
        b = self.rfile.read(n)
        self.send_response(200)
        self.send_header('Content-Type','application/octet-stream')
        self.send_header('Content-Length', str(len(b)))
        self.end_headers()
        self.wfile.write(b)
    def log_message(self, *a, **k): pass
http.server.HTTPServer(('127.0.0.1', int(sys.argv[1])), Echo).serve_forever()
PY

port=$((30600 + RANDOM % 18000))
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
    --form 'greeting=hi-there' \
    "http://127.0.0.1:$port/upload" -o "$tmpdir/got.bin"

validator_assert_contains "$tmpdir/got.bin" 'greeting'
validator_assert_contains "$tmpdir/got.bin" 'hi-there'
grep -F -- '------------------------' "$tmpdir/got.bin" >/dev/null || {
    printf 'expected a multipart boundary marker in body\n' >&2
    head -c 200 "$tmpdir/got.bin" >&2
    exit 1
}

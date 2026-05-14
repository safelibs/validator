#!/usr/bin/env bash
# @testcase: usage-curl-r18-head-flag-content-length
# @title: curl -I prints response headers including Content-Length
# @description: Stands up a python loopback http.server that returns a fixed thirteen-byte body with an explicit Content-Length header, issues curl -I against /size, and asserts the captured output contains both "HTTP/" status and "Content-Length: 13" — locking in HEAD-style header retrieval.
# @timeout: 90
# @tags: usage, curl, head, content-length, r18
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
class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        body = b'thirteenbytes'
        self.send_response(200); self.send_header('Content-Type','text/plain'); self.send_header('Content-Length', str(len(body))); self.end_headers(); self.wfile.write(body)
    def do_HEAD(self):
        body = b'thirteenbytes'
        self.send_response(200); self.send_header('Content-Type','text/plain'); self.send_header('Content-Length', str(len(body))); self.end_headers()
    def log_message(self, *a, **k): pass
http.server.HTTPServer(('127.0.0.1', int(sys.argv[1])), Handler).serve_forever()
PY

port=$((30400 + RANDOM % 18000))
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

curl --noproxy '*' -fsS --max-time 5 -I \
    "http://127.0.0.1:$port/size" >"$tmpdir/headers.txt"

validator_assert_contains "$tmpdir/headers.txt" 'HTTP/'
validator_assert_contains "$tmpdir/headers.txt" 'Content-Length: 13'

#!/usr/bin/env bash
# @testcase: usage-curl-r18-header-custom-x-token
# @title: curl --header forwards a custom X-Request-Id header to the server
# @description: Stands up a python loopback http.server that echoes the inbound X-Request-Id request header in the response body, issues curl --header 'X-Request-Id: token-abc-123', and asserts the captured body equals exactly "token-abc-123".
# @timeout: 90
# @tags: usage, curl, header, custom, r18
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
        v = self.headers.get('X-Request-Id', '<absent>')
        body = v.encode('utf-8')
        self.send_response(200); self.send_header('Content-Type','text/plain'); self.send_header('Content-Length', str(len(body))); self.end_headers(); self.wfile.write(body)
    def log_message(self, *a, **k): pass
http.server.HTTPServer(('127.0.0.1', int(sys.argv[1])), Echo).serve_forever()
PY

port=$((30900 + RANDOM % 18000))
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
    --header 'X-Request-Id: token-abc-123' \
    "http://127.0.0.1:$port/r" -o "$tmpdir/got.txt"

got=$(cat "$tmpdir/got.txt")
[[ "$got" == "token-abc-123" ]] || {
    printf 'expected "token-abc-123", got %q\n' "$got" >&2
    exit 1
}

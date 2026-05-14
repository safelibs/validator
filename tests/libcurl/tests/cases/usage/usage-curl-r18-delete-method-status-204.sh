#!/usr/bin/env bash
# @testcase: usage-curl-r18-delete-method-status-204
# @title: curl -X DELETE against a /resource endpoint receives the expected 204 No Content status
# @description: Stands up a python loopback http.server whose do_DELETE handler returns 204 with no body, issues curl -X DELETE with -w '%{http_code}', and asserts the captured status token equals "204" — locking in the DELETE method dispatch and no-content response handling.
# @timeout: 90
# @tags: usage, curl, delete, status, r18
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
        b=b'ok'; self.send_response(200); self.send_header('Content-Length', str(len(b))); self.end_headers(); self.wfile.write(b)
    def do_DELETE(self):
        self.send_response(204); self.send_header('Content-Length','0'); self.end_headers()
    def log_message(self, *a, **k): pass
http.server.HTTPServer(('127.0.0.1', int(sys.argv[1])), Handler).serve_forever()
PY

port=$((30700 + RANDOM % 18000))
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

got=$(curl --noproxy '*' -sS --max-time 5 \
    -X DELETE \
    -o /dev/null -w '%{http_code}' \
    "http://127.0.0.1:$port/resource")

[[ "$got" == "204" ]] || {
    printf 'expected 204, got %q\n' "$got" >&2
    exit 1
}

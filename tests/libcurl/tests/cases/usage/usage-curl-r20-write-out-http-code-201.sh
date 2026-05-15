#!/usr/bin/env bash
# @testcase: usage-curl-r20-write-out-http-code-201
# @title: curl -w "%{http_code}" surfaces a 201 Created status from a loopback server
# @description: Stands up a python loopback http.server that responds 201 Created to POST, then issues curl -X POST -o /dev/null -w '%{http_code}' and asserts the captured value equals "201" - locking in write-out HTTP code reporting on a non-200 success path.
# @timeout: 90
# @tags: usage, curl, write-out, http-code, 201, r20
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
        self.send_response(201)
        self.send_header('Content-Length','0')
        self.end_headers()
    def log_message(self,*a,**k): pass
http.server.HTTPServer(('127.0.0.1', int(sys.argv[1])), H).serve_forever()
PY

port=$((40700 + RANDOM % 18000))
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

got=$(curl --noproxy '*' -sS --max-time 5 -X POST -o /dev/null -w '%{http_code}' "http://127.0.0.1:$port/x")
[[ "$got" == "201" ]] || {
    printf 'expected "201", got %q\n' "$got" >&2
    exit 1
}

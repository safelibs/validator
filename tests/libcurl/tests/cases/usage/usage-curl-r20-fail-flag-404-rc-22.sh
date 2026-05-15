#!/usr/bin/env bash
# @testcase: usage-curl-r20-fail-flag-404-rc-22
# @title: curl -f exits with code 22 when the server returns 404
# @description: Stands up a python loopback http.server that always responds 404 Not Found, then runs curl -f -o /dev/null and asserts curl exits with code 22 - locking in the --fail flag's non-zero exit on HTTP error.
# @timeout: 90
# @tags: usage, curl, fail, 404, exit-code, r20
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
        b=b'not found'
        # /.ping is reachable so curl readiness probe succeeds.
        if self.path == '/.ping':
            self.send_response(200); self.send_header('Content-Length','2'); self.end_headers(); self.wfile.write(b'ok'); return
        self.send_response(404); self.send_header('Content-Length', str(len(b))); self.end_headers(); self.wfile.write(b)
    def log_message(self,*a,**k): pass
http.server.HTTPServer(('127.0.0.1', int(sys.argv[1])), H).serve_forever()
PY

port=$((41200 + RANDOM % 18000))
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

set +e
curl --noproxy '*' -f -sS --max-time 5 -o /dev/null "http://127.0.0.1:$port/missing"
rc=$?
set -e
[[ "$rc" -eq 22 ]] || {
    printf 'expected exit 22, got %s\n' "$rc" >&2
    exit 1
}

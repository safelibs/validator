#!/usr/bin/env bash
# @testcase: usage-curl-r21-empty-header-via-semicolon
# @title: curl -H "X-Empty;" emits the named header with empty value
# @description: Stands up a python loopback http.server that echoes the received X-Empty header value into the response body, then issues curl -H "X-Empty;" (the semicolon syntax to force an empty-value header) and asserts the server saw the X-Empty header present with an empty string - locking in libcurl's empty-header injection via the semicolon syntax.
# @timeout: 90
# @tags: usage, curl, header, empty-header, r21
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
        v=self.headers.get('X-Empty', None)
        body=('present|' + (v if v is not None else 'MISSING')).encode('utf-8')
        self.send_response(200); self.send_header('Content-Length', str(len(body))); self.end_headers(); self.wfile.write(body)
    def log_message(self,*a,**k): pass
http.server.HTTPServer(('127.0.0.1', int(sys.argv[1])), H).serve_forever()
PY

port=$((42100 + RANDOM % 17000))
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

got=$(curl --noproxy '*' -sS --max-time 5 -H 'X-Empty;' "http://127.0.0.1:$port/x")
[[ "$got" == "present|" ]] || {
    printf 'expected "present|", got %q\n' "$got" >&2
    exit 1
}

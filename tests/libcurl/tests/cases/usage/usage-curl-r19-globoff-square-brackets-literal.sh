#!/usr/bin/env bash
# @testcase: usage-curl-r19-globoff-square-brackets-literal
# @title: curl -g treats square brackets in the URL path as literal characters
# @description: Stands up a python loopback http.server that echoes the request path in the response body, fetches "/q[1]" with curl -g, and asserts the echoed path equals "/q[1]" - locking in -g globbing-off behavior so bracket characters reach the wire as-is.
# @timeout: 90
# @tags: usage, curl, globoff, brackets, r19
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
        b=self.path.encode()
        self.send_response(200); self.send_header('Content-Length', str(len(b))); self.end_headers(); self.wfile.write(b)
    def log_message(self,*a,**k): pass
http.server.HTTPServer(('127.0.0.1', int(sys.argv[1])), H).serve_forever()
PY

port=$((41000 + RANDOM % 18000))
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

got=$(curl --noproxy '*' -fsS --max-time 5 -g "http://127.0.0.1:$port/q[1]")
[[ "$got" == "/q[1]" ]] || {
    printf 'expected "/q[1]", got %q\n' "$got" >&2
    exit 1
}

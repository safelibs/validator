#!/usr/bin/env bash
# @testcase: usage-curl-r21-write-out-response-code-alias
# @title: curl -w "%{response_code}" surfaces the HTTP status as the http_code alias
# @description: Stands up a python loopback http.server that returns 200 OK, then issues curl -w '%{response_code}' against it and asserts the captured value is "200" - locking in the response_code write-out token (alias for http_code) which is distinct from the existing http_code-201/204/404/200 tests by exercising the alias form specifically.
# @timeout: 90
# @tags: usage, curl, write-out, response-code, r21
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
    def log_message(self,*a,**k): pass
http.server.HTTPServer(('127.0.0.1', int(sys.argv[1])), H).serve_forever()
PY

port=$((42300 + RANDOM % 17000))
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

got=$(curl --noproxy '*' -sS --max-time 5 -o /dev/null -w '%{response_code}' "http://127.0.0.1:$port/")
[[ "$got" == "200" ]] || {
    printf 'expected "200", got %q\n' "$got" >&2
    exit 1
}

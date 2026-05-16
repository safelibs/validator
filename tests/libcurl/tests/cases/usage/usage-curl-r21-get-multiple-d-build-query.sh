#!/usr/bin/env bash
# @testcase: usage-curl-r21-get-multiple-d-build-query
# @title: curl --get combines two -d fragments into one ampersand-joined query
# @description: Stands up a python loopback http.server that echoes the request path, then issues curl --get with two separate -d "k1=v1" -d "k2=v2" flags against it and asserts the path echoed back includes "k1=v1&k2=v2" - locking in --get's multi-fragment query assembly behavior at two fragments specifically.
# @timeout: 90
# @tags: usage, curl, get, multi-d, query, r21
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
        b=self.path.encode('utf-8'); self.send_response(200); self.send_header('Content-Length', str(len(b))); self.end_headers(); self.wfile.write(b)
    def log_message(self,*a,**k): pass
http.server.HTTPServer(('127.0.0.1', int(sys.argv[1])), H).serve_forever()
PY

port=$((42500 + RANDOM % 17000))
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

got=$(curl --noproxy '*' -sS --max-time 5 --get -d 'k1=v1' -d 'k2=v2' "http://127.0.0.1:$port/path")
[[ "$got" == "/path?k1=v1&k2=v2" ]] || {
    printf 'expected "/path?k1=v1&k2=v2", got %q\n' "$got" >&2
    exit 1
}

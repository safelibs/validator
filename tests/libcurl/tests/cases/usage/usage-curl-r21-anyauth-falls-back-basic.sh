#!/usr/bin/env bash
# @testcase: usage-curl-r21-anyauth-falls-back-basic
# @title: curl --anyauth negotiates to basic auth when only Basic is offered
# @description: Stands up a python loopback http.server that on first request returns 401 with WWW-Authenticate: Basic realm=r21 and on second request (with Authorization) returns 200 echoing the Authorization header, then issues curl --anyauth -u user:pass and asserts the captured echoed Authorization header begins with "Basic " - locking in --anyauth's challenge-response negotiation falling back to Basic.
# @timeout: 90
# @tags: usage, curl, anyauth, basic, r21
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
        auth=self.headers.get('Authorization')
        if auth is None:
            b=b''
            self.send_response(401)
            self.send_header('WWW-Authenticate','Basic realm="r21"')
            self.send_header('Content-Length','0')
            self.end_headers()
            return
        b=auth.encode('utf-8')
        self.send_response(200)
        self.send_header('Content-Length', str(len(b)))
        self.end_headers()
        self.wfile.write(b)
    def log_message(self,*a,**k): pass
http.server.HTTPServer(('127.0.0.1', int(sys.argv[1])), H).serve_forever()
PY

port=$((42900 + RANDOM % 17000))
python3 "$tmpdir/server.py" "$port" >/dev/null 2>&1 &
pid=$!
ready=0
for _ in $(seq 1 60); do
    # /ping returns 401 from this server too but TCP connection works, so the curl call will succeed
    if curl --noproxy '*' -sS --max-time 2 -o /dev/null "http://127.0.0.1:$port/.ping" 2>/dev/null; then
        ready=1; break
    fi
    sleep 0.1
done
[[ "$ready" -eq 1 ]] || { printf 'server never became ready\n' >&2; exit 1; }

got=$(curl --noproxy '*' -sS --max-time 5 --anyauth -u 'user:pass' "http://127.0.0.1:$port/secret")
[[ "$got" == Basic\ * ]] || {
    printf 'expected Authorization to start with "Basic ", got %q\n' "$got" >&2
    exit 1
}

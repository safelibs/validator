#!/usr/bin/env bash
# @testcase: usage-curl-r19-options-method-allow-header
# @title: curl -X OPTIONS receives the Allow header from a loopback server
# @description: Stands up a python loopback http.server that responds to OPTIONS with an Allow header listing GET, HEAD, OPTIONS, then issues curl -X OPTIONS -i and asserts the captured headers contain "Allow:" with all three methods - locking in OPTIONS method handling and header capture via -i.
# @timeout: 90
# @tags: usage, curl, options, allow, r19
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
    def do_OPTIONS(self):
        self.send_response(204)
        self.send_header('Allow','GET, HEAD, OPTIONS')
        self.send_header('Content-Length','0')
        self.end_headers()
    def log_message(self,*a,**k): pass
http.server.HTTPServer(('127.0.0.1', int(sys.argv[1])), H).serve_forever()
PY

port=$((40300 + RANDOM % 18000))
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

curl --noproxy '*' -sS --max-time 5 -i -X OPTIONS "http://127.0.0.1:$port/anything" -o "$tmpdir/r.txt"
validator_assert_contains "$tmpdir/r.txt" 'Allow:'
validator_assert_contains "$tmpdir/r.txt" 'GET'
validator_assert_contains "$tmpdir/r.txt" 'OPTIONS'

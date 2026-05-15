#!/usr/bin/env bash
# @testcase: usage-curl-r19-post-empty-body-rc-zero
# @title: curl POST with an empty body succeeds and observes Content-Length 0
# @description: Stands up a python loopback http.server that echoes back the value of the Content-Length request header on POST, issues curl -X POST -d '' with no body, and asserts the captured echo equals "0" and exit code is 0 - locking in empty-body POST behavior.
# @timeout: 90
# @tags: usage, curl, post, empty-body, r19
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
        cl = self.headers.get('Content-Length', 'unset').encode()
        # consume body
        try:
            n = int(self.headers.get('Content-Length','0'))
            if n>0: self.rfile.read(n)
        except ValueError:
            pass
        self.send_response(200); self.send_header('Content-Length', str(len(cl))); self.end_headers(); self.wfile.write(cl)
    def log_message(self,*a,**k): pass
http.server.HTTPServer(('127.0.0.1', int(sys.argv[1])), H).serve_forever()
PY

port=$((40900 + RANDOM % 18000))
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

got=$(curl --noproxy '*' -fsS --max-time 5 -X POST -d '' "http://127.0.0.1:$port/p")
[[ "$got" == "0" ]] || {
    printf 'expected Content-Length echo "0", got %q\n' "$got" >&2
    exit 1
}

#!/usr/bin/env bash
# @testcase: usage-curl-r20-resolve-fake-host
# @title: curl --resolve maps a fake hostname to 127.0.0.1 and fetches a loopback body
# @description: Stands up a python loopback http.server bound to 127.0.0.1, then issues curl with --resolve fake.r20.local:<port>:127.0.0.1 against http://fake.r20.local:<port>/ and asserts the response body equals "ok" - locking in client-side hostname-to-IP override.
# @timeout: 90
# @tags: usage, curl, resolve, hostmap, r20
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

port=$((41400 + RANDOM % 18000))
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

got=$(curl --noproxy '*' -fsS --max-time 5 --resolve "fake.r20.local:$port:127.0.0.1" "http://fake.r20.local:$port/")
[[ "$got" == "ok" ]] || {
    printf 'expected "ok", got %q\n' "$got" >&2
    exit 1
}

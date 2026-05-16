#!/usr/bin/env bash
# @testcase: usage-curl-r21-write-out-url-effective-shape
# @title: curl -w "%{url_effective}" emits the full http://127.0.0.1:port/path URL after request
# @description: Stands up a python loopback http.server, issues curl -w '%{url_effective}' against a /alpha path, and asserts the captured URL equals exactly the request URL string - locking in url_effective on a non-redirect path (existing url-effective-after-redirect test covers redirected URLs; this exercises the no-redirect case).
# @timeout: 90
# @tags: usage, curl, write-out, url-effective, r21
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

port=$((43500 + RANDOM % 17000))
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

url="http://127.0.0.1:$port/alpha"
got=$(curl --noproxy '*' -sS --max-time 5 -o /dev/null -w '%{url_effective}' "$url")
[[ "$got" == "$url" ]] || {
    printf 'expected %q, got %q\n' "$url" "$got" >&2
    exit 1
}

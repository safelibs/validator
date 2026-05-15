#!/usr/bin/env bash
# @testcase: usage-curl-r19-referer-header-echo
# @title: curl --referer sets the Referer request header observed by the server
# @description: Stands up a python loopback http.server that echoes the value of the Referer header in the body, issues curl --referer 'https://example.test/origin', and asserts the recovered body equals that exact URL - locking in --referer header delivery.
# @timeout: 90
# @tags: usage, curl, referer, header, r19
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
        ref = self.headers.get('Referer', '').encode()
        self.send_response(200); self.send_header('Content-Length', str(len(ref))); self.end_headers(); self.wfile.write(ref)
    def log_message(self,*a,**k): pass
http.server.HTTPServer(('127.0.0.1', int(sys.argv[1])), H).serve_forever()
PY

port=$((40700 + RANDOM % 18000))
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

got=$(curl --noproxy '*' -fsS --max-time 5 --referer 'https://example.test/origin' "http://127.0.0.1:$port/")
[[ "$got" == "https://example.test/origin" ]] || {
    printf 'expected referer echo, got %q\n' "$got" >&2
    exit 1
}

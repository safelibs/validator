#!/usr/bin/env bash
# @testcase: usage-curl-r21-write-out-num-headers-positive
# @title: curl -w "%{num_headers}" reports at least three response headers on loopback
# @description: Stands up a python loopback http.server that returns Content-Type, Content-Length, and X-Marker headers, then issues curl -w '%{num_headers}' and asserts the captured number is >= 3 - locking in num_headers write-out token reporting (existing num-headers-positive test is simpler - this version asserts a specific lower bound).
# @timeout: 90
# @tags: usage, curl, write-out, num-headers, r21
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
        b=b'ok'
        self.send_response(200)
        self.send_header('Content-Type','text/plain')
        self.send_header('Content-Length', str(len(b)))
        self.send_header('X-Marker','r21')
        self.end_headers()
        self.wfile.write(b)
    def log_message(self,*a,**k): pass
http.server.HTTPServer(('127.0.0.1', int(sys.argv[1])), H).serve_forever()
PY

port=$((42700 + RANDOM % 17000))
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

n=$(curl --noproxy '*' -sS --max-time 5 -o /dev/null -w '%{num_headers}' "http://127.0.0.1:$port/")
[[ "$n" =~ ^[0-9]+$ ]] || { printf 'expected numeric, got %q\n' "$n" >&2; exit 1; }
[[ "$n" -ge 3 ]] || { printf 'expected >=3 headers, got %s\n' "$n" >&2; exit 1; }

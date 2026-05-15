#!/usr/bin/env bash
# @testcase: usage-curl-r20-write-out-num-headers-positive
# @title: curl -w "%{num_headers}" reports at least one response header
# @description: Stands up a python loopback http.server that returns a small response with several headers, then issues curl -w '%{num_headers}' and asserts the captured value is a positive integer - locking in the num_headers write-out variable.
# @timeout: 90
# @tags: usage, curl, write-out, num-headers, r20
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
        self.send_header('X-One','1')
        self.send_header('X-Two','2')
        self.send_header('Content-Length', str(len(b)))
        self.end_headers(); self.wfile.write(b)
    def log_message(self,*a,**k): pass
http.server.HTTPServer(('127.0.0.1', int(sys.argv[1])), H).serve_forever()
PY

port=$((40800 + RANDOM % 18000))
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

got=$(curl --noproxy '*' -sS --max-time 5 -o /dev/null -w '%{num_headers}' "http://127.0.0.1:$port/")
[[ "$got" =~ ^[0-9]+$ ]] || { printf 'expected digits, got %q\n' "$got" >&2; exit 1; }
[[ "$got" -ge 1 ]] || {
    printf 'expected at least 1 header, got %s\n' "$got" >&2
    exit 1
}

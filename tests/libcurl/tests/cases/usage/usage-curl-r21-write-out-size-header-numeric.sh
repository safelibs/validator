#!/usr/bin/env bash
# @testcase: usage-curl-r21-write-out-size-header-numeric
# @title: curl -w "%{size_header}" reports a positive numeric byte count on loopback
# @description: Stands up a python loopback http.server returning a small body, issues curl -w '%{size_header}' against it, and asserts the captured value is a positive integer greater than 30 (since headers always include Content-Length and HTTP/1.x status line) - locking in size_header write-out reporting (existing size-header test from r15 exists; this version pins a numeric lower bound).
# @timeout: 90
# @tags: usage, curl, write-out, size-header, r21
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

port=$((43700 + RANDOM % 17000))
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

got=$(curl --noproxy '*' -sS --max-time 5 -o /dev/null -w '%{size_header}' "http://127.0.0.1:$port/")
[[ "$got" =~ ^[0-9]+$ ]] || { printf 'expected numeric, got %q\n' "$got" >&2; exit 1; }
[[ "$got" -gt 30 ]] || { printf 'expected size_header > 30, got %s\n' "$got" >&2; exit 1; }

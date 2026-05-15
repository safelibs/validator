#!/usr/bin/env bash
# @testcase: usage-curl-r20-include-headers-status-line
# @title: curl -i prepends an HTTP/1.x 200 status line to the output body
# @description: Stands up a python loopback http.server that returns 200 OK with a body, then issues curl -i and asserts the captured output begins with an HTTP status line ending in "200" - locking in -i header-inclusion before the body.
# @timeout: 90
# @tags: usage, curl, include-headers, status-line, r20
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

port=$((41600 + RANDOM % 18000))
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

curl --noproxy '*' -sS --max-time 5 -i "http://127.0.0.1:$port/" -o "$tmpdir/r.txt"
first=$(head -n1 "$tmpdir/r.txt" | tr -d '\r')
case "$first" in
    HTTP/*' 200'*) ;;
    *) printf 'expected HTTP/x 200 status line, got %q\n' "$first" >&2; exit 1 ;;
esac

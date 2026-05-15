#!/usr/bin/env bash
# @testcase: usage-curl-r19-write-out-content-type-json
# @title: curl -w "%{content_type}" surfaces the server-declared Content-Type
# @description: Stands up a python loopback http.server that returns Content-Type "application/json; charset=utf-8", then issues curl with -w '%{content_type}' and asserts the captured token contains "application/json" - locking in the content_type write-out variable.
# @timeout: 90
# @tags: usage, curl, write-out, content-type, r19
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
        b=b'{"k":1}'
        self.send_response(200)
        self.send_header('Content-Type','application/json; charset=utf-8')
        self.send_header('Content-Length', str(len(b)))
        self.end_headers(); self.wfile.write(b)
    def log_message(self,*a,**k): pass
http.server.HTTPServer(('127.0.0.1', int(sys.argv[1])), H).serve_forever()
PY

port=$((40200 + RANDOM % 18000))
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

got=$(curl --noproxy '*' -sS --max-time 5 -o /dev/null -w '%{content_type}' "http://127.0.0.1:$port/")
case "$got" in
    *application/json*) ;;
    *) printf 'expected application/json in content_type, got %q\n' "$got" >&2; exit 1 ;;
esac

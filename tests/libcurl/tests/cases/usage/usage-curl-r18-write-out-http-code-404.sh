#!/usr/bin/env bash
# @testcase: usage-curl-r18-write-out-http-code-404
# @title: curl -w prints the http_code 404 when the loopback server responds with not-found
# @description: Stands up a python loopback http.server that returns 404 with an empty body on /missing, then issues curl with -w '%{http_code}' against /missing and asserts the captured token is exactly "404" — locking in the write-out http_code variable on a non-2xx status.
# @timeout: 90
# @tags: usage, curl, write-out, 404, r18
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
class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path.startswith('/missing'):
            self.send_response(404); self.send_header('Content-Length','0'); self.end_headers()
        else:
            body=b'ok'; self.send_response(200); self.send_header('Content-Length', str(len(body))); self.end_headers(); self.wfile.write(body)
    def log_message(self, *a, **k): pass
http.server.HTTPServer(('127.0.0.1', int(sys.argv[1])), Handler).serve_forever()
PY

port=$((30200 + RANDOM % 18000))
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

got=$(curl --noproxy '*' -sS --max-time 5 \
    -o /dev/null \
    -w '%{http_code}' \
    "http://127.0.0.1:$port/missing")

[[ "$got" == "404" ]] || {
    printf 'expected http_code 404, got %q\n' "$got" >&2
    exit 1
}

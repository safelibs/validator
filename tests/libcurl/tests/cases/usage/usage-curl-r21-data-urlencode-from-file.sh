#!/usr/bin/env bash
# @testcase: usage-curl-r21-data-urlencode-from-file
# @title: curl --data-urlencode "key@file" percent-encodes the file contents as the value
# @description: Stands up a python loopback http.server that echoes the POST body, writes a tempfile containing "hello world", then issues curl --data-urlencode "msg@<file>" and asserts the echoed body equals "msg=hello+world" (curl renders space as "+" in application/x-www-form-urlencoded) - locking in --data-urlencode's filename-source ("@file") encoding behavior.
# @timeout: 90
# @tags: usage, curl, data-urlencode, file, r21
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
        n=int(self.headers.get('Content-Length','0'))
        b=self.rfile.read(n)
        self.send_response(200); self.send_header('Content-Length', str(len(b))); self.end_headers(); self.wfile.write(b)
    def log_message(self,*a,**k): pass
http.server.HTTPServer(('127.0.0.1', int(sys.argv[1])), H).serve_forever()
PY

port=$((43300 + RANDOM % 17000))
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

printf 'hello world' >"$tmpdir/value.txt"
got=$(curl --noproxy '*' -sS --max-time 5 --data-urlencode "msg@$tmpdir/value.txt" "http://127.0.0.1:$port/echo")
[[ "$got" == "msg=hello+world" ]] || {
    printf 'expected "msg=hello+world", got %q\n' "$got" >&2
    exit 1
}

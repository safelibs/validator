#!/usr/bin/env bash
# @testcase: usage-curl-r16-header-flag-roundtrip
# @title: curl -H sends a custom header that the loopback server echoes back
# @description: Stands up a python http.server handler that echoes the X-R16-Token request header value into the response body, then asserts curl -H 'X-R16-Token: alpha-bravo' delivers the same value back to the client byte-for-byte.
# @timeout: 60
# @tags: usage, curl, header, roundtrip
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
class Echo(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        token = self.headers.get('X-R16-Token', '<absent>')
        body = token.encode('utf-8')
        self.send_response(200)
        self.send_header('Content-Type','text/plain')
        self.send_header('Content-Length', str(len(body)))
        self.end_headers()
        self.wfile.write(body)
    def log_message(self, *a, **k): pass
port=int(sys.argv[1])
http.server.HTTPServer(('127.0.0.1', port), Echo).serve_forever()
PY

port=$((23400 + RANDOM % 19000))
python3 "$tmpdir/server.py" "$port" >/dev/null 2>&1 &
pid=$!
for _ in $(seq 1 60); do
    curl --noproxy '*' -fsS --max-time 2 -o /dev/null "http://127.0.0.1:$port/" 2>/dev/null && break
    sleep 0.1
done

curl --noproxy '*' -fsS --max-time 5 \
    -H 'X-R16-Token: alpha-bravo' \
    "http://127.0.0.1:$port/echo" -o "$tmpdir/got.txt"

got=$(cat "$tmpdir/got.txt")
[[ "$got" == "alpha-bravo" ]] || {
    printf 'expected alpha-bravo, got %q\n' "$got" >&2
    exit 1
}

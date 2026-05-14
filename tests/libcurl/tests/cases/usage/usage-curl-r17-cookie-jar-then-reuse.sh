#!/usr/bin/env bash
# @testcase: usage-curl-r17-cookie-jar-then-reuse
# @title: curl --cookie-jar writes a file then --cookie reuses it on a second request
# @description: Stands up a python http.server that sets a Set-Cookie header on /set and echoes the inbound Cookie header on /echo, then issues a first curl with --cookie-jar against /set, asserts the jar file exists, and issues a second curl with --cookie <jar> against /echo confirming the cookie roundtrips.
# @timeout: 120
# @tags: usage, curl, cookie-jar
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
        if self.path.startswith('/set'):
            body = b'ok'
            self.send_response(200)
            self.send_header('Set-Cookie', 'jarkey=jarvalue; Path=/')
            self.send_header('Content-Type', 'text/plain')
            self.send_header('Content-Length', str(len(body)))
            self.end_headers()
            self.wfile.write(body)
        elif self.path.startswith('/echo'):
            c = self.headers.get('Cookie', '<absent>')
            body = c.encode('utf-8')
            self.send_response(200)
            self.send_header('Content-Type', 'text/plain')
            self.send_header('Content-Length', str(len(body)))
            self.end_headers()
            self.wfile.write(body)
        else:
            self.send_response(200)
            self.send_header('Content-Length','0')
            self.end_headers()
    def log_message(self, *a, **k):
        pass
http.server.HTTPServer(('127.0.0.1', int(sys.argv[1])), Handler).serve_forever()
PY

port=$((24800 + RANDOM % 18000))
python3 "$tmpdir/server.py" "$port" >/dev/null 2>&1 &
pid=$!
ready=0
for _ in $(seq 1 60); do
    if curl --noproxy '*' -fsS --max-time 2 -o /dev/null "http://127.0.0.1:$port/.ping" 2>/dev/null; then
        ready=1
        break
    fi
    sleep 0.1
done
[[ "$ready" -eq 1 ]] || { printf 'server never became ready\n' >&2; exit 1; }

jar="$tmpdir/jar.txt"
curl --noproxy '*' -fsS --max-time 5 \
    --cookie-jar "$jar" \
    "http://127.0.0.1:$port/set" -o "$tmpdir/set.out"

[[ -s "$jar" ]] || {
    printf 'expected non-empty cookie jar at %s\n' "$jar" >&2
    ls -la "$tmpdir" >&2
    exit 1
}
grep -F 'jarkey' "$jar" >/dev/null || {
    printf 'jar missing jarkey entry\n' >&2
    cat "$jar" >&2
    exit 1
}

curl --noproxy '*' -fsS --max-time 5 \
    --cookie "$jar" \
    "http://127.0.0.1:$port/echo" -o "$tmpdir/echo.out"

validator_assert_contains "$tmpdir/echo.out" 'jarkey=jarvalue'

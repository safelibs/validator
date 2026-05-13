#!/usr/bin/env bash
# @testcase: usage-curl-r16-form-multipart-loopback
# @title: curl -F posts multipart/form-data with named field to a loopback echo
# @description: Stands up a small python http.server that returns the raw POST body, then issues curl -F 'tag=value-r16' and asserts the resulting body contains both the field name "tag" and the literal value "value-r16" in multipart form encoding.
# @timeout: 60
# @tags: usage, curl, form, multipart
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
    def do_POST(self):
        n = int(self.headers.get('Content-Length', '0'))
        body = self.rfile.read(n)
        self.send_response(200)
        self.send_header('Content-Type', self.headers.get('Content-Type','text/plain'))
        self.send_header('Content-Length', str(len(body)))
        self.end_headers()
        self.wfile.write(body)
    def log_message(self, *a, **k): pass
http.server.HTTPServer(('127.0.0.1', int(sys.argv[1])), Echo).serve_forever()
PY

port=$((23700 + RANDOM % 19000))
python3 "$tmpdir/server.py" "$port" >/dev/null 2>&1 &
pid=$!
for _ in $(seq 1 60); do
    curl --noproxy '*' -fsS --max-time 2 -X POST --data 'p' "http://127.0.0.1:$port/" >/dev/null 2>&1 && break
    sleep 0.1
done

curl --noproxy '*' -fsS --max-time 5 \
    -F 'tag=value-r16' \
    "http://127.0.0.1:$port/echo" -o "$tmpdir/got.bin"

validator_assert_contains "$tmpdir/got.bin" 'name="tag"'
validator_assert_contains "$tmpdir/got.bin" 'value-r16'

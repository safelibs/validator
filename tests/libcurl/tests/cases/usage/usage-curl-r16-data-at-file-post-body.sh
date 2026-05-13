#!/usr/bin/env bash
# @testcase: usage-curl-r16-data-at-file-post-body
# @title: curl --data @file sends the file body as the POST payload
# @description: Builds a small file and asserts that curl --data @file against a loopback echo server posts the file's content as the request body, locking in the @-prefixed --data file-load path. Uses a python http.server subclass that echoes POST bodies back as text.
# @timeout: 60
# @tags: usage, curl, post, data, file
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
        self.send_header('Content-Type','application/octet-stream')
        self.send_header('Content-Length', str(len(body)))
        self.end_headers()
        self.wfile.write(body)
    def log_message(self, *a, **k): pass
port=int(sys.argv[1])
http.server.HTTPServer(('127.0.0.1', port), Echo).serve_forever()
PY

port=$((23300 + RANDOM % 19000))
python3 "$tmpdir/server.py" "$port" >/dev/null 2>&1 &
pid=$!
for _ in $(seq 1 60); do
    curl --noproxy '*' -fsS --max-time 2 -X POST --data 'ping' "http://127.0.0.1:$port/" \
        >/dev/null 2>&1 && break
    sleep 0.1
done

printf 'r16 data-at-file payload bytes\n' >"$tmpdir/body.txt"

curl --noproxy '*' -fsS --max-time 5 \
    --data "@$tmpdir/body.txt" \
    "http://127.0.0.1:$port/echo" -o "$tmpdir/got.txt"

# curl --data collapses newlines, so compare against the trimmed expected form.
expected=$(tr -d '\n' <"$tmpdir/body.txt")
got=$(cat "$tmpdir/got.txt")
[[ "$got" == "$expected" ]] || {
    printf 'expected %q, got %q\n' "$expected" "$got" >&2
    exit 1
}

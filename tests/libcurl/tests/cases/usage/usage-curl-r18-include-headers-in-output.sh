#!/usr/bin/env bash
# @testcase: usage-curl-r18-include-headers-in-output
# @title: curl -i prepends the HTTP status line and headers to the response body
# @description: Stands up a python loopback http.server that returns the body "payload-only" with a custom X-Trace header, issues curl -i, and asserts the captured output contains the HTTP status line, the custom X-Trace header value, and the body — locking in the -i (include) flag's header-in-output behavior.
# @timeout: 90
# @tags: usage, curl, include, headers, r18
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
        body=b'payload-only'
        self.send_response(200)
        self.send_header('Content-Type','text/plain')
        self.send_header('X-Trace','trace-r18')
        self.send_header('Content-Length', str(len(body)))
        self.end_headers()
        self.wfile.write(body)
    def log_message(self, *a, **k): pass
http.server.HTTPServer(('127.0.0.1', int(sys.argv[1])), Handler).serve_forever()
PY

port=$((30800 + RANDOM % 18000))
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

curl --noproxy '*' -fsS --max-time 5 -i \
    "http://127.0.0.1:$port/r" -o "$tmpdir/got.txt"

validator_assert_contains "$tmpdir/got.txt" 'HTTP/'
validator_assert_contains "$tmpdir/got.txt" '200'
validator_assert_contains "$tmpdir/got.txt" 'X-Trace: trace-r18'
validator_assert_contains "$tmpdir/got.txt" 'payload-only'

#!/usr/bin/env bash
# @testcase: usage-curl-r18-output-to-stdout-dash
# @title: curl -o - writes the response body to stdout where the calling shell can capture it
# @description: Stands up a python loopback http.server that returns the body "stdout-payload", issues curl with -o - and redirects stdout to a file, and asserts the captured content equals "stdout-payload" — locking in the -o - convention as an explicit stdout sink.
# @timeout: 90
# @tags: usage, curl, output, stdout, r18
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
        body=b'stdout-payload'
        self.send_response(200); self.send_header('Content-Type','text/plain'); self.send_header('Content-Length', str(len(body))); self.end_headers(); self.wfile.write(body)
    def log_message(self, *a, **k): pass
http.server.HTTPServer(('127.0.0.1', int(sys.argv[1])), Handler).serve_forever()
PY

port=$((31000 + RANDOM % 18000))
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

curl --noproxy '*' -fsS --max-time 5 \
    -o - \
    "http://127.0.0.1:$port/p" >"$tmpdir/got.txt"

got=$(cat "$tmpdir/got.txt")
[[ "$got" == "stdout-payload" ]] || {
    printf 'expected "stdout-payload", got %q\n' "$got" >&2
    exit 1
}

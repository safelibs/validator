#!/usr/bin/env bash
# @testcase: usage-curl-r18-range-middle-bytes
# @title: curl --range 4-7 returns the four middle bytes of the response body
# @description: Stands up a python loopback http.server that serves a fixed ten-byte body "0123456789" with explicit Content-Length, issues curl --range 4-7 against it, and asserts the captured output equals exactly "4567" — locking in byte-range request semantics.
# @timeout: 90
# @tags: usage, curl, range, r18
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
BODY = b'0123456789'
class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        r = self.headers.get('Range', '')
        if r.startswith('bytes='):
            spec = r[len('bytes='):]
            try:
                a, b = spec.split('-', 1)
                start = int(a) if a else 0
                end = int(b) if b else len(BODY) - 1
                chunk = BODY[start:end+1]
                self.send_response(206)
                self.send_header('Content-Type','application/octet-stream')
                self.send_header('Content-Range', f'bytes {start}-{end}/{len(BODY)}')
                self.send_header('Content-Length', str(len(chunk)))
                self.end_headers()
                self.wfile.write(chunk)
                return
            except Exception:
                pass
        self.send_response(200)
        self.send_header('Content-Type','application/octet-stream')
        self.send_header('Content-Length', str(len(BODY)))
        self.end_headers()
        self.wfile.write(BODY)
    def log_message(self, *a, **k): pass
http.server.HTTPServer(('127.0.0.1', int(sys.argv[1])), Handler).serve_forever()
PY

port=$((30500 + RANDOM % 18000))
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
    --range 4-7 \
    "http://127.0.0.1:$port/body" -o "$tmpdir/got.txt"

got=$(cat "$tmpdir/got.txt")
[[ "$got" == "4567" ]] || {
    printf 'range mismatch: want=%q got=%q\n' "4567" "$got" >&2
    exit 1
}

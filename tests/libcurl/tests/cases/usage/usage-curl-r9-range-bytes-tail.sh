#!/usr/bin/env bash
# @testcase: usage-curl-r9-range-bytes-tail
# @title: curl --range fetches trailing bytes
# @description: Requests the trailing 5 bytes of a known payload via --range against a loopback server and validates the partial response matches the file tail.
# @timeout: 180
# @tags: usage, curl, http, range
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

printf 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' >"$tmpdir/data.bin"

port=$((24500 + RANDOM % 8000))
python3 - "$port" "$tmpdir/data.bin" <<'PY' >/dev/null 2>&1 &
import sys, http.server, os
port = int(sys.argv[1])
path = sys.argv[2]
class H(http.server.BaseHTTPRequestHandler):
    def log_message(self, *a, **k): pass
    def do_GET(self):
        body = open(path, 'rb').read()
        rng = self.headers.get('Range')
        if rng and rng.startswith('bytes='):
            spec = rng[len('bytes='):]
            if '-' in spec:
                a, b = spec.split('-', 1)
                start = int(a) if a else 0
                end = int(b) if b else len(body) - 1
                chunk = body[start:end + 1]
                self.send_response(206)
                self.send_header('Content-Type', 'application/octet-stream')
                self.send_header('Content-Length', str(len(chunk)))
                self.send_header('Content-Range', f'bytes {start}-{end}/{len(body)}')
                self.end_headers()
                self.wfile.write(chunk)
                return
        self.send_response(200)
        self.send_header('Content-Type', 'application/octet-stream')
        self.send_header('Content-Length', str(len(body)))
        self.end_headers()
        self.wfile.write(body)
http.server.HTTPServer(('127.0.0.1', port), H).serve_forever()
PY
pid=$!
for _ in $(seq 1 50); do
  curl -fsS --max-time 2 -o /dev/null "http://127.0.0.1:$port/data" 2>/dev/null && break
  sleep 0.1
done

curl -fsS --max-time 5 --range 21- -o "$tmpdir/tail" "http://127.0.0.1:$port/data"
got=$(cat "$tmpdir/tail")
[[ "$got" == "VWXYZ" ]] || {
  printf 'expected VWXYZ, got %s\n' "$got" >&2
  exit 1
}

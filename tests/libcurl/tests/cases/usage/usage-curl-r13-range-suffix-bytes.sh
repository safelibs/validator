#!/usr/bin/env bash
# @testcase: usage-curl-r13-range-suffix-bytes
# @title: curl --range -3 fetches the trailing 3 bytes of a Range-aware loopback server
# @description: Hosts a 20-byte payload behind a custom loopback handler that honors the Range header (including suffix-byte ranges of the form bytes=-N), asserts curl --range -3 returns the last three bytes "hij" with HTTP 206.
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

cat >"$tmpdir/server.py" <<'PY'
from http.server import BaseHTTPRequestHandler, HTTPServer
import os
class H(BaseHTTPRequestHandler):
    def log_message(self, *a, **k): pass
    def do_GET(self):
        body = b'0123456789abcdefghij'
        rng = self.headers.get('Range')
        if rng and rng.startswith('bytes='):
            spec = rng[6:]
            a, b = spec.split('-')
            if a == '' and b != '':
                # suffix-bytes form: last b bytes
                n = int(b)
                start = len(body) - n
                end = len(body) - 1
                part = body[start:end+1]
            else:
                start = int(a) if a else 0
                end = int(b) if b else len(body) - 1
                part = body[start:end+1]
            self.send_response(206)
            self.send_header('Content-Type', 'application/octet-stream')
            self.send_header('Content-Range', f'bytes {start}-{end}/{len(body)}')
            self.send_header('Content-Length', str(len(part)))
            self.end_headers()
            self.wfile.write(part)
        else:
            self.send_response(200)
            self.send_header('Content-Type', 'application/octet-stream')
            self.send_header('Accept-Ranges', 'bytes')
            self.send_header('Content-Length', str(len(body)))
            self.end_headers()
            self.wfile.write(body)
HTTPServer(('127.0.0.1', int(os.environ['PORT'])), H).serve_forever()
PY

port=$((23000 + RANDOM % 19000))
PORT="$port" python3 "$tmpdir/server.py" >/dev/null 2>&1 &
pid=$!
for _ in $(seq 1 60); do
    curl --noproxy '*' -fsS --max-time 2 -o /dev/null "http://127.0.0.1:$port/" 2>/dev/null && break
    sleep 0.1
done

code=$(curl --noproxy '*' -sS --max-time 5 --range -3 \
    -o "$tmpdir/part.bin" -w '%{response_code}' "http://127.0.0.1:$port/")
[[ "$code" == "206" ]] || {
    printf 'expected 206, got %q\n' "$code" >&2
    exit 1
}
[[ "$(wc -c <"$tmpdir/part.bin")" == "3" ]] || {
    printf 'expected 3 bytes, got %d\n' "$(wc -c <"$tmpdir/part.bin")" >&2
    exit 1
}
[[ "$(cat "$tmpdir/part.bin")" == "hij" ]] || {
    printf 'expected body hij, got %q\n' "$(cat "$tmpdir/part.bin")" >&2
    exit 1
}

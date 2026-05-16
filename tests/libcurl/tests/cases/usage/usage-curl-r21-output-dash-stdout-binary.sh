#!/usr/bin/env bash
# @testcase: usage-curl-r21-output-dash-stdout-binary
# @title: curl -o - writes a 256-byte binary payload to stdout byte-for-byte
# @description: Stands up a python loopback http.server returning a 256-byte payload covering bytes 0x00-0xFF, issues curl -o - (explicit stdout) capturing into a file, and asserts the captured bytes match the source payload by SHA-256 - locking in -o - explicit-stdout dispatch on a binary payload distinct from prior -o-to-stdout-dash tests using ASCII bodies.
# @timeout: 90
# @tags: usage, curl, output-stdout, binary, r21
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
PAYLOAD=bytes(range(256))
class H(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200); self.send_header('Content-Type','application/octet-stream'); self.send_header('Content-Length', str(len(PAYLOAD))); self.end_headers(); self.wfile.write(PAYLOAD)
    def log_message(self,*a,**k): pass
http.server.HTTPServer(('127.0.0.1', int(sys.argv[1])), H).serve_forever()
PY

port=$((43900 + RANDOM % 17000))
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

curl --noproxy '*' -sS --max-time 5 -o - "http://127.0.0.1:$port/blob" >"$tmpdir/got.bin"

# Expected SHA-256 of bytes 0..255
expected=$(python3 -c 'import hashlib; print(hashlib.sha256(bytes(range(256))).hexdigest())')
got=$(sha256sum "$tmpdir/got.bin" | awk '{print $1}')
[[ "$got" == "$expected" ]] || {
    printf 'sha256 mismatch: expected %s got %s\n' "$expected" "$got" >&2
    exit 1
}
n=$(wc -c <"$tmpdir/got.bin")
[[ "$n" -eq 256 ]] || { printf 'expected 256 bytes, got %s\n' "$n" >&2; exit 1; }

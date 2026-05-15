#!/usr/bin/env bash
# @testcase: usage-curl-r19-output-file-from-loopback
# @title: curl -o writes the response body byte-for-byte to a named file
# @description: Stands up a python loopback http.server that returns a known 32-byte payload, fetches with curl -o into a target path, and asserts the on-disk file is exactly 32 bytes and sha256-matches the expected payload - locking in -o output fidelity.
# @timeout: 90
# @tags: usage, curl, output, fidelity, r19
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
PAYLOAD = ('abcd' * 8).encode()
assert len(PAYLOAD) == 32
class H(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200); self.send_header('Content-Length', str(len(PAYLOAD))); self.end_headers(); self.wfile.write(PAYLOAD)
    def log_message(self,*a,**k): pass
http.server.HTTPServer(('127.0.0.1', int(sys.argv[1])), H).serve_forever()
PY

port=$((40400 + RANDOM % 18000))
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

curl --noproxy '*' -fsS --max-time 5 -o "$tmpdir/got.bin" "http://127.0.0.1:$port/payload"

n=$(wc -c <"$tmpdir/got.bin")
[[ "$n" -eq 32 ]] || { printf 'expected 32 bytes, got %s\n' "$n" >&2; exit 1; }
want='abcdabcdabcdabcdabcdabcdabcdabcd'
got=$(cat "$tmpdir/got.bin")
[[ "$got" == "$want" ]] || { printf 'content mismatch: got %q\n' "$got" >&2; exit 1; }

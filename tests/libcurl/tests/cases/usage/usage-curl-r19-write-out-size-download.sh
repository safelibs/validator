#!/usr/bin/env bash
# @testcase: usage-curl-r19-write-out-size-download
# @title: curl -w "%{size_download}" reports the body byte count of a fixed payload
# @description: Stands up a python loopback http.server that always returns a 13-byte body, then issues curl with -w '%{size_download}' and asserts the captured value is exactly "13" - locking in the size_download write-out variable on a known fixed-size response.
# @timeout: 90
# @tags: usage, curl, write-out, size-download, r19
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
class H(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        b=b'hello world!\n'
        self.send_response(200); self.send_header('Content-Length', str(len(b))); self.end_headers(); self.wfile.write(b)
    def log_message(self,*a,**k): pass
http.server.HTTPServer(('127.0.0.1', int(sys.argv[1])), H).serve_forever()
PY

port=$((40100 + RANDOM % 18000))
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

got=$(curl --noproxy '*' -sS --max-time 5 -o /dev/null -w '%{size_download}' "http://127.0.0.1:$port/")
[[ "$got" == "13" ]] || {
    printf 'expected size_download "13", got %q\n' "$got" >&2
    exit 1
}

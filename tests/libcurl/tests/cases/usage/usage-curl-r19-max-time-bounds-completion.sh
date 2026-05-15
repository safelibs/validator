#!/usr/bin/env bash
# @testcase: usage-curl-r19-max-time-bounds-completion
# @title: curl --max-time succeeds on a fast loopback response well under the budget
# @description: Stands up a python loopback http.server with an immediate response, issues curl --max-time 10 against /fast, and asserts the response body equals "fast-ok" with exit code 0 - locking in --max-time non-interference when the transfer completes promptly.
# @timeout: 90
# @tags: usage, curl, max-time, r19
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
        b=b'fast-ok'
        self.send_response(200); self.send_header('Content-Length', str(len(b))); self.end_headers(); self.wfile.write(b)
    def log_message(self,*a,**k): pass
http.server.HTTPServer(('127.0.0.1', int(sys.argv[1])), H).serve_forever()
PY

port=$((40600 + RANDOM % 18000))
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

got=$(curl --noproxy '*' -fsS --max-time 10 "http://127.0.0.1:$port/fast")
[[ "$got" == "fast-ok" ]] || {
    printf 'expected "fast-ok", got %q\n' "$got" >&2
    exit 1
}

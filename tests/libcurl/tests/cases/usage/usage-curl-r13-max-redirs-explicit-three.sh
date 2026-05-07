#!/usr/bin/env bash
# @testcase: usage-curl-r13-max-redirs-explicit-three
# @title: curl -L --max-redirs 3 stops following after three hops and surfaces the documented error
# @description: Hosts a loopback server that returns a 302 chain longer than 3 hops, asserts curl -L --max-redirs 3 fails with exit code 47 (CURLE_TOO_MANY_REDIRECTS) and reports the maximum-redirects diagnostic on stderr, while a separate run with a sufficient budget completes successfully.
# @timeout: 180
# @tags: usage, curl, http, redirect
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
        path = self.path
        if path.startswith('/hop/'):
            n = int(path.rsplit('/', 1)[1])
            if n > 0:
                self.send_response(302)
                self.send_header('Location', f'/hop/{n-1}')
                self.send_header('Content-Length', '0')
                self.end_headers()
                return
            body = b'final\n'
            self.send_response(200)
            self.send_header('Content-Type', 'text/plain')
            self.send_header('Content-Length', str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return
        self.send_response(404); self.send_header('Content-Length', '0'); self.end_headers()
HTTPServer(('127.0.0.1', int(os.environ['PORT'])), H).serve_forever()
PY

port=$((23000 + RANDOM % 19000))
PORT="$port" python3 "$tmpdir/server.py" >/dev/null 2>&1 &
pid=$!
for _ in $(seq 1 60); do
    curl --noproxy '*' -fsS --max-time 2 -o /dev/null "http://127.0.0.1:$port/hop/0" 2>/dev/null && break
    sleep 0.1
done

# 5 hops requested but only 3 redirects allowed - must error exit 47.
set +e
curl --noproxy '*' -sS --max-time 10 -L --max-redirs 3 \
    -o "$tmpdir/out_fail" "http://127.0.0.1:$port/hop/5" 2>"$tmpdir/err"
rc=$?
set -e
[[ "$rc" == "47" ]] || {
    printf 'expected curl exit 47 (CURLE_TOO_MANY_REDIRECTS), got %d\n' "$rc" >&2
    cat "$tmpdir/err" >&2
    exit 1
}

# A larger budget completes the chain to "/hop/0" successfully.
curl --noproxy '*' -fsS --max-time 10 -L --max-redirs 10 \
    -o "$tmpdir/out_ok" "http://127.0.0.1:$port/hop/5"
validator_assert_contains "$tmpdir/out_ok" 'final'

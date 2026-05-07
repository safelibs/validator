#!/usr/bin/env bash
# @testcase: usage-curl-r12-retry-delay-respected
# @title: curl --retry --retry-delay succeeds against a server that becomes ready on the second request
# @description: Hosts a loopback handler that returns HTTP 503 on the first hit and HTTP 200 on the second, runs curl --retry 2 --retry-delay 1 against /flaky, and asserts the second attempt yields a 200 with the expected body.
# @timeout: 180
# @tags: usage, curl, http, retry
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
import os, threading
state = {'hits': 0}
lock = threading.Lock()
class H(BaseHTTPRequestHandler):
    def log_message(self, *a, **k): pass
    def do_GET(self):
        if self.path == '/flaky':
            with lock:
                state['hits'] += 1
                n = state['hits']
            if n < 2:
                self.send_response(503)
                self.send_header('Content-Length', '0')
                self.end_headers()
            else:
                body = b'flaky-ok\n'
                self.send_response(200)
                self.send_header('Content-Type', 'text/plain')
                self.send_header('Content-Length', str(len(body)))
                self.end_headers()
                self.wfile.write(body)
        else:
            self.send_response(200)
            self.send_header('Content-Length', '0')
            self.end_headers()
HTTPServer(('127.0.0.1', int(os.environ['PORT'])), H).serve_forever()
PY

port=$((23000 + RANDOM % 19000))
PORT="$port" python3 "$tmpdir/server.py" >/dev/null 2>&1 &
pid=$!
for _ in $(seq 1 60); do
    curl --noproxy '*' -fsS --max-time 2 -o /dev/null "http://127.0.0.1:$port/" 2>/dev/null && break
    sleep 0.1
done

code=$(curl --noproxy '*' -sS --max-time 20 \
            --retry 2 --retry-delay 1 \
            -o "$tmpdir/body" -w '%{response_code}' \
            "http://127.0.0.1:$port/flaky")
[[ "$code" == "200" ]] || {
    printf 'expected 200 after retry, got %q\n' "$code" >&2
    exit 1
}
validator_assert_contains "$tmpdir/body" 'flaky-ok'

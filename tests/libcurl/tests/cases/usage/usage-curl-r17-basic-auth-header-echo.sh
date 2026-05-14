#!/usr/bin/env bash
# @testcase: usage-curl-r17-basic-auth-header-echo
# @title: curl --user user:pass sends an Authorization Basic header echoed by loopback
# @description: Stands up a python http.server that echoes the Authorization request header into the response body, then runs curl --user 'alpha:secret' and confirms the body starts with "Basic " and decodes back to "alpha:secret" via base64.
# @timeout: 90
# @tags: usage, curl, basic-auth
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
class Echo(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        a = self.headers.get('Authorization', '<absent>')
        body = a.encode('utf-8')
        self.send_response(200)
        self.send_header('Content-Type', 'text/plain')
        self.send_header('Content-Length', str(len(body)))
        self.end_headers()
        self.wfile.write(body)
    def log_message(self, *a, **k):
        pass
http.server.HTTPServer(('127.0.0.1', int(sys.argv[1])), Echo).serve_forever()
PY

port=$((24500 + RANDOM % 18000))
python3 "$tmpdir/server.py" "$port" >/dev/null 2>&1 &
pid=$!
ready=0
for _ in $(seq 1 60); do
    if curl --noproxy '*' -fsS --max-time 2 -o /dev/null "http://127.0.0.1:$port/.ping" 2>/dev/null; then
        ready=1
        break
    fi
    sleep 0.1
done
[[ "$ready" -eq 1 ]] || { printf 'server never became ready\n' >&2; exit 1; }

curl --noproxy '*' -fsS --max-time 5 \
    --user 'alpha:secret' \
    "http://127.0.0.1:$port/echo" -o "$tmpdir/got.txt"

validator_assert_contains "$tmpdir/got.txt" 'Basic '
decoded=$(python3 -c "
import base64, sys
with open(sys.argv[1], 'rb') as f:
    h = f.read().decode('utf-8').strip()
assert h.startswith('Basic '), h
print(base64.b64decode(h.split(' ',1)[1]).decode('utf-8'))
" "$tmpdir/got.txt")
[[ "$decoded" == "alpha:secret" ]] || {
    printf 'expected decoded "alpha:secret", got %q\n' "$decoded" >&2
    exit 1
}

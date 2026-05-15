#!/usr/bin/env bash
# @testcase: usage-curl-r20-user-agent-flag-echo
# @title: curl -A sets a custom User-Agent that the loopback server echoes
# @description: Stands up a python loopback http.server that echoes the request's User-Agent header in the response body, then issues curl -A 'validator-r20/1.0' and asserts the recovered body contains the literal "validator-r20/1.0" - locking in -A user-agent override behavior.
# @timeout: 90
# @tags: usage, curl, user-agent, r20
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
        ua=self.headers.get('User-Agent','').encode()
        self.send_response(200); self.send_header('Content-Length', str(len(ua))); self.end_headers(); self.wfile.write(ua)
    def log_message(self,*a,**k): pass
http.server.HTTPServer(('127.0.0.1', int(sys.argv[1])), H).serve_forever()
PY

port=$((40900 + RANDOM % 18000))
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

curl --noproxy '*' -fsS --max-time 5 -A 'validator-r20/1.0' "http://127.0.0.1:$port/" -o "$tmpdir/body"
validator_assert_contains "$tmpdir/body" 'validator-r20/1.0'

#!/usr/bin/env bash
# @testcase: usage-curl-r21-config-file-multiple-options
# @title: curl -K config file applies header and silent flag together
# @description: Stands up a python loopback http.server that echoes the X-CfgR21 header, writes a multi-line curl config file containing both `silent` and a `header = "X-CfgR21: ok"` directive, then runs curl -K with the config file plus the URL and asserts the captured body is exactly "ok" - locking in multi-option config-file loading distinct from prior config-from-stdin tests.
# @timeout: 90
# @tags: usage, curl, config-file, r21
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
        v=self.headers.get('X-CfgR21','MISSING').encode('utf-8')
        self.send_response(200); self.send_header('Content-Length', str(len(v))); self.end_headers(); self.wfile.write(v)
    def log_message(self,*a,**k): pass
http.server.HTTPServer(('127.0.0.1', int(sys.argv[1])), H).serve_forever()
PY

port=$((43100 + RANDOM % 17000))
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

cat >"$tmpdir/curl.cfg" <<EOF
silent
noproxy = "*"
header = "X-CfgR21: ok"
max-time = 5
EOF

got=$(curl -K "$tmpdir/curl.cfg" "http://127.0.0.1:$port/")
[[ "$got" == "ok" ]] || {
    printf 'expected "ok", got %q\n' "$got" >&2
    exit 1
}

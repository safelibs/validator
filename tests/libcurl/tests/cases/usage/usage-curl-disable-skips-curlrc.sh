#!/usr/bin/env bash
# @testcase: usage-curl-disable-skips-curlrc
# @title: curl -q skips ~/.curlrc
# @description: Places a header directive in $HOME/.curlrc that would inject X-FromRc and confirms invoking curl -q sends a request whose echoed headers omit the rc-injected header.
# @timeout: 180
# @tags: usage, curl, config
# @client: curl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-curl-disable-skips-curlrc"
tmpdir=$(mktemp -d)
pid=""
cleanup() {
  if [[ -n "$pid" ]]; then
    kill "$pid" 2>/dev/null || true
    wait "$pid" 2>/dev/null || true
  fi
  rm -rf "$tmpdir"
}
trap cleanup EXIT

cat >"$tmpdir/server.py" <<'PY'
from http.server import BaseHTTPRequestHandler, HTTPServer
import os

class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        return
    def do_GET(self):
        body = ('FromRc=' + self.headers.get('X-FromRc', 'absent') + '\n').encode()
        self.send_response(200)
        self.send_header('Content-Type', 'text/plain')
        self.send_header('Content-Length', str(len(body)))
        self.end_headers()
        self.wfile.write(body)

HTTPServer(('127.0.0.1', int(os.environ['PORT'])), Handler).serve_forever()
PY

port=$((29000 + RANDOM % 10000))
PORT="$port" python3 "$tmpdir/server.py" >"$tmpdir/server.log" 2>&1 &
pid=$!
for _ in $(seq 1 50); do
  curl -fsS "http://127.0.0.1:$port/" >/dev/null 2>&1 && break
  sleep 0.1
done

mkdir -p "$tmpdir/home"
cat >"$tmpdir/home/.curlrc" <<'EOF'
header = "X-FromRc: should-not-appear"
EOF

# Sanity: rc would be loaded without -q.
HOME="$tmpdir/home" curl -fsS "http://127.0.0.1:$port/" >"$tmpdir/with-rc"
validator_assert_contains "$tmpdir/with-rc" 'FromRc=should-not-appear'

HOME="$tmpdir/home" curl -q -fsS "http://127.0.0.1:$port/" >"$tmpdir/without-rc"
validator_assert_contains "$tmpdir/without-rc" 'FromRc=absent'

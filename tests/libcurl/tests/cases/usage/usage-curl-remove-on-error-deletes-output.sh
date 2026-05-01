#!/usr/bin/env bash
# @testcase: usage-curl-remove-on-error-deletes-output
# @title: curl --remove-on-error removes partial output
# @description: Talks to a loopback server that advertises a longer Content-Length than it sends so curl reports a transfer-closed error after writing some bytes. Without --remove-on-error the partial file is kept; with --remove-on-error curl deletes it. Verifies both behaviors.
# @timeout: 180
# @tags: usage, curl, http
# @client: curl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-curl-remove-on-error-deletes-output"
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

cat >"$tmpdir/server.py" <<'PYCASE'
from http.server import BaseHTTPRequestHandler, HTTPServer
import os

class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        return
    def do_GET(self):
        self.send_response(200)
        self.send_header('Content-Type', 'application/octet-stream')
        self.send_header('Content-Length', '100')
        self.end_headers()
        self.wfile.write(b'X' * 30)

HTTPServer(('127.0.0.1', int(os.environ['PORT'])), Handler).serve_forever()
PYCASE

port=$((29000 + RANDOM % 10000))
PORT="$port" python3 "$tmpdir/server.py" >"$tmpdir/server.log" 2>&1 &
pid=$!
for _ in $(seq 1 50); do
  if curl -sS --max-time 2 -o /dev/null "http://127.0.0.1:$port/probe" 2>/dev/null; then
    break
  fi
  if (printf '' >/dev/tcp/127.0.0.1/"$port") 2>/dev/null; then
    break
  fi
  sleep 0.1
done

# Without --remove-on-error: curl errors, partial file is kept.
set +e
curl -sS -o "$tmpdir/leftover" "http://127.0.0.1:$port/x" 2>"$tmpdir/err1"
rc1=$?
set -e
[[ $rc1 -ne 0 ]]
test -e "$tmpdir/leftover"

# With --remove-on-error: same error, but file is removed.
set +e
curl -sS --remove-on-error -o "$tmpdir/cleaned" "http://127.0.0.1:$port/x" 2>"$tmpdir/err2"
rc2=$?
set -e
[[ $rc2 -ne 0 ]]
[[ ! -e "$tmpdir/cleaned" ]]

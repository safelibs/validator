#!/usr/bin/env bash
# @testcase: usage-curl-writeout-header-json
# @title: curl write-out emits header JSON
# @description: Uses curl -w '%{header_json}' to dump response headers as JSON and verifies a custom header from the loopback server appears as a JSON key.
# @timeout: 180
# @tags: usage, curl, http
# @client: curl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-curl-writeout-header-json"
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
        body = b'hj-body\n'
        self.send_response(200)
        self.send_header('Content-Type', 'text/plain')
        self.send_header('X-Validator-Marker', 'header-json-marker-value')
        self.send_header('Content-Length', str(len(body)))
        self.end_headers()
        self.wfile.write(body)

HTTPServer(('127.0.0.1', int(os.environ['PORT'])), Handler).serve_forever()
PYCASE

port=$((29000 + RANDOM % 10000))
PORT="$port" python3 "$tmpdir/server.py" >"$tmpdir/server.log" 2>&1 &
pid=$!
for _ in $(seq 1 50); do
  if curl -fsS "http://127.0.0.1:$port/" >/dev/null 2>&1; then
    break
  fi
  sleep 0.1
done

curl -fsS -o /dev/null -w '%{header_json}\n' "http://127.0.0.1:$port/" >"$tmpdir/out"
python3 -c '
import json, sys
data = json.loads(open(sys.argv[1]).read())
keys = {k.lower() for k in data}
assert "x-validator-marker" in keys, sorted(keys)
values = data.get("X-Validator-Marker") or data.get("x-validator-marker") or []
joined = " ".join(values)
assert "header-json-marker-value" in joined, joined
' "$tmpdir/out"

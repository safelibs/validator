#!/usr/bin/env bash
# @testcase: usage-curl-r10-write-out-response-code-204
# @title: curl --write-out response_code reflects 204 No Content
# @description: Posts to a loopback server returning 204 No Content and asserts %{response_code} is exactly 204 with no response body printed.
# @timeout: 180
# @tags: usage, curl, http, write-out
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
    def do_POST(self):
        n = int(self.headers.get('Content-Length', '0'))
        self.rfile.read(n)
        self.send_response(204)
        self.end_headers()

HTTPServer(('127.0.0.1', int(os.environ['PORT'])), H).serve_forever()
PY

port=$((29000 + RANDOM % 8000))
PORT="$port" python3 "$tmpdir/server.py" >/dev/null 2>&1 &
pid=$!
for _ in $(seq 1 50); do
  curl -fsS --max-time 2 --data 'p=1' -o /dev/null "http://127.0.0.1:$port/" 2>/dev/null && break
  sleep 0.1
done

code=$(curl -sS --max-time 5 --data 'r=10' -o "$tmpdir/body" -w '%{response_code}' "http://127.0.0.1:$port/")
[[ "$code" == "204" ]] || {
  printf 'expected response_code 204, got %q\n' "$code" >&2
  exit 1
}
[[ ! -s "$tmpdir/body" ]] || {
  printf 'expected empty body for 204, got %d bytes\n' "$(wc -c <"$tmpdir/body")" >&2
  exit 1
}

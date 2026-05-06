#!/usr/bin/env bash
# @testcase: usage-curl-r9-write-out-num-redirects
# @title: curl --write-out reports num_redirects
# @description: Follows a chain of two server-side redirects and validates curl exposes the expected redirect count via %{num_redirects}.
# @timeout: 180
# @tags: usage, curl, http, redirects
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
        if self.path == "/a":
            self.send_response(302); self.send_header("Location", "/b"); self.end_headers()
        elif self.path == "/b":
            self.send_response(302); self.send_header("Location", "/c"); self.end_headers()
        elif self.path == "/c":
            body = b"final\n"
            self.send_response(200)
            self.send_header("Content-Length", str(len(body)))
            self.end_headers(); self.wfile.write(body)
        else:
            self.send_response(404); self.end_headers()

HTTPServer(("127.0.0.1", int(os.environ["PORT"])), H).serve_forever()
PY

port=$((25000 + RANDOM % 8000))
PORT="$port" python3 "$tmpdir/server.py" >/dev/null 2>&1 &
pid=$!
for _ in $(seq 1 50); do
  curl -fsS --max-time 2 -o /dev/null "http://127.0.0.1:$port/c" 2>/dev/null && break
  sleep 0.1
done

n=$(curl -fsSL --max-time 5 -o /dev/null -w '%{num_redirects}' "http://127.0.0.1:$port/a")
[[ "$n" == "2" ]] || {
  printf 'expected 2 redirects, got %s\n' "$n" >&2
  exit 1
}

#!/usr/bin/env bash
# @testcase: usage-curl-max-redirs-zero-error
# @title: curl --max-redirs 0 errors on redirect
# @description: With --location and --max-redirs 0, curl must refuse to follow any redirect and exit with a non-zero status.
# @timeout: 180
# @tags: usage, http, cli
# @client: curl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-curl-max-redirs-zero-error"
tmpdir=$(mktemp -d)
trap 'jobs -pr | xargs -r kill 2>/dev/null || true; rm -rf "$tmpdir"' EXIT

start_server() {
  local port=$1
  cat >"$tmpdir/server.py" <<'PY'
from http.server import BaseHTTPRequestHandler, HTTPServer
import sys

class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        return
    def do_GET(self):
        if self.path == "/start":
            self.send_response(302)
            self.send_header("Location", "/dest")
            self.send_header("Content-Length", "0")
            self.end_headers()
            return
        body = b"final\n"
        self.send_response(200)
        self.send_header("Content-Type", "text/plain")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

HTTPServer(("127.0.0.1", int(sys.argv[1])), Handler).serve_forever()
PY
  python3 "$tmpdir/server.py" "$port" >"$tmpdir/server.log" 2>&1 &
  for _ in $(seq 1 40); do
    curl -fsS "http://127.0.0.1:$port/dest" >/dev/null 2>&1 && return 0
    sleep 0.2
  done
  cat "$tmpdir/server.log" >&2
  return 1
}

port=$((22500 + RANDOM % 1000))
start_server "$port"
base="http://127.0.0.1:$port"

set +e
curl -sS --location --max-redirs 0 -o "$tmpdir/out" "$base/start" >"$tmpdir/stdout" 2>"$tmpdir/stderr"
status=$?
set -e

if [[ $status -eq 0 ]]; then
  printf 'expected curl to fail with --max-redirs 0, got status 0\n' >&2
  cat "$tmpdir/stderr" >&2
  exit 1
fi

# Confirm the unfollowed destination is reachable directly (sanity-check on server).
curl -fsS "$base/dest" >"$tmpdir/dest"
validator_assert_contains "$tmpdir/dest" 'final'

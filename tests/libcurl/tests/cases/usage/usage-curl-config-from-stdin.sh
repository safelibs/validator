#!/usr/bin/env bash
# @testcase: usage-curl-config-from-stdin
# @title: curl -K - reads config options from stdin
# @description: Pipes a curl config block into curl -K - so url and header options are parsed from standard input, and verifies the loopback server echoes the configured custom header.
# @timeout: 180
# @tags: usage, curl, http, config
# @client: curl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-curl-config-from-stdin"
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
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import os

class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        return

    def _send(self, status, body=b""):
        self.send_response(status)
        self.send_header("Content-Type", "text/plain")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        marker = self.headers.get("X-Validator-Config", "missing")
        self._send(200, ("config-header=" + marker + "\n").encode())

ThreadingHTTPServer(("127.0.0.1", int(os.environ["PORT"])), Handler).serve_forever()
PYCASE

port=$((29000 + RANDOM % 10000))
PORT="$port" python3 "$tmpdir/server.py" >"$tmpdir/server.log" 2>&1 &
pid=$!
for _ in $(seq 1 50); do
  if curl --noproxy '*' -fsS "http://127.0.0.1:$port/probe" >/dev/null 2>&1; then
    break
  fi
  sleep 0.1
done

# Pipe a config block into `curl -K -` so options are parsed from stdin.
http_code=$(printf '%s\n' \
  "url = \"http://127.0.0.1:$port/echo\"" \
  'header = "X-Validator-Config: stdin-config-value"' \
  'noproxy = "*"' \
  'silent' \
  | curl -K - -sS \
      -o "$tmpdir/out" -w '%{http_code}')

[[ "$http_code" == "200" ]] || {
  printf 'expected http_code 200, got %s\n' "$http_code" >&2
  exit 1
}

validator_assert_contains "$tmpdir/out" 'config-header=stdin-config-value'

#!/usr/bin/env bash
# @testcase: usage-curl-parallel-multi-transfer
# @title: curl -Z parallel runs multiple transfers concurrently
# @description: Issues two GETs in a single curl invocation with -Z (parallel) so transfers run concurrently against the loopback server, and verifies both response bodies are written to their distinct output files with the expected content.
# @timeout: 180
# @tags: usage, curl, http, parallel
# @client: curl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-curl-parallel-multi-transfer"
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
        if self.path == "/red":
            self._send(200, b"parallel-payload-red\n")
        elif self.path == "/blue":
            self._send(200, b"parallel-payload-blue\n")
        else:
            self._send(200, b"probe-ok\n")

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

# -Z is curl's parallel flag; combined with --next + -o to disambiguate outputs.
curl --noproxy '*' -fsS -Z \
  -o "$tmpdir/red.out" "http://127.0.0.1:$port/red" \
  --next \
  -o "$tmpdir/blue.out" "http://127.0.0.1:$port/blue"

validator_assert_contains "$tmpdir/red.out" 'parallel-payload-red'
validator_assert_contains "$tmpdir/blue.out" 'parallel-payload-blue'

# Cross-check non-empty saved files.
[[ -s "$tmpdir/red.out" ]] || { printf 'red.out empty\n' >&2; exit 1; }
[[ -s "$tmpdir/blue.out" ]] || { printf 'blue.out empty\n' >&2; exit 1; }

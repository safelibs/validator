#!/usr/bin/env bash
# @testcase: usage-curl-retry-zero-no-retry-5xx
# @title: curl --retry 0 does not retry 5xx
# @description: Hits a loopback handler that increments a counter on every request and verifies that --retry 0 --fail produces exactly one request even on a 503.
# @timeout: 180
# @tags: usage, http, cli
# @client: curl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-curl-retry-zero-no-retry-5xx"
tmpdir=$(mktemp -d)
trap 'jobs -pr | xargs -r kill 2>/dev/null || true; rm -rf "$tmpdir"' EXIT

start_server() {
  local port=$1
  cat >"$tmpdir/server.py" <<'PY'
from http.server import BaseHTTPRequestHandler, HTTPServer
import os
import sys
from pathlib import Path

state = Path(os.environ["STATE_DIR"])
state.mkdir(parents=True, exist_ok=True)
counter = state / "hits"

class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        return
    def do_GET(self):
        if self.path == "/probe":
            body = b"probe\n"
            self.send_response(200)
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return
        n = int(counter.read_text()) if counter.exists() else 0
        n += 1
        counter.write_text(str(n))
        body = ("hit=" + str(n) + "\n").encode()
        self.send_response(503)
        self.send_header("Content-Type", "text/plain")
        self.send_header("Retry-After", "0")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

HTTPServer(("127.0.0.1", int(sys.argv[1])), Handler).serve_forever()
PY
  STATE_DIR="$tmpdir/state" python3 "$tmpdir/server.py" "$port" >"$tmpdir/server.log" 2>&1 &
  for _ in $(seq 1 40); do
    curl -fsS "http://127.0.0.1:$port/probe" >/dev/null 2>&1 && return 0
    sleep 0.2
  done
  cat "$tmpdir/server.log" >&2
  return 1
}

port=$((22700 + RANDOM % 1000))
start_server "$port"
base="http://127.0.0.1:$port"

set +e
curl -sS --retry 0 --fail \
  -o "$tmpdir/out" \
  -w '%{http_code}\n' \
  "$base/flaky" >"$tmpdir/code" 2>"$tmpdir/stderr"
status=$?
set -e

if [[ $status -eq 0 ]]; then
  printf 'expected curl --fail to exit non-zero on 503\n' >&2
  exit 1
fi

validator_assert_contains "$tmpdir/code" '503'

# Verify only a single request was made (no retry).
hits=$(cat "$tmpdir/state/hits")
if [[ "$hits" != "1" ]]; then
  printf 'expected exactly 1 server hit, got %s\n' "$hits" >&2
  exit 1
fi

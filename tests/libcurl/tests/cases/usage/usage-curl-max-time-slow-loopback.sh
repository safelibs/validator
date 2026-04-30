#!/usr/bin/env bash
# @testcase: usage-curl-max-time-slow-loopback
# @title: curl --max-time aborts slow loopback response
# @description: Targets a loopback handler that sleeps before responding and verifies curl --max-time 1 aborts the transfer with exit code 28.
# @timeout: 120
# @tags: usage, http, cli
# @client: curl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-curl-max-time-slow-loopback"
tmpdir=$(mktemp -d)
trap 'jobs -pr | xargs -r kill 2>/dev/null || true; rm -rf "$tmpdir"' EXIT

start_server() {
  local port=$1
  cat >"$tmpdir/server.py" <<'PY'
from http.server import BaseHTTPRequestHandler, HTTPServer
import sys
import time

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
        # Slow path: stall well past curl --max-time 1.
        time.sleep(10)
        body = b"slow\n"
        self.send_response(200)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

HTTPServer(("127.0.0.1", int(sys.argv[1])), Handler).serve_forever()
PY
  python3 "$tmpdir/server.py" "$port" >"$tmpdir/server.log" 2>&1 &
  for _ in $(seq 1 40); do
    curl -fsS "http://127.0.0.1:$port/probe" >/dev/null 2>&1 && return 0
    sleep 0.2
  done
  cat "$tmpdir/server.log" >&2
  return 1
}

port=$((22800 + RANDOM % 1000))
start_server "$port"
base="http://127.0.0.1:$port"

start_ts=$(date +%s)
set +e
curl -sS --max-time 1 -o "$tmpdir/out" "$base/slow" >"$tmpdir/stdout" 2>"$tmpdir/stderr"
status=$?
set -e
end_ts=$(date +%s)
elapsed=$((end_ts - start_ts))

if [[ $status -ne 28 ]]; then
  printf 'expected curl exit code 28 (timeout), got %s\n' "$status" >&2
  cat "$tmpdir/stderr" >&2
  exit 1
fi

if (( elapsed > 8 )); then
  printf 'curl honoured --max-time too slowly: %ss\n' "$elapsed" >&2
  exit 1
fi

#!/usr/bin/env bash
# @testcase: usage-curl-no-progress-meter-quiet
# @title: curl --no-progress-meter suppresses progress output
# @description: Confirms --no-progress-meter keeps stdout body intact while emitting no progress meter on stderr (errors still go to stderr separately).
# @timeout: 120
# @tags: usage, http, cli
# @client: curl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-curl-no-progress-meter-quiet"
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
        body = b"x" * 4096 + b"\n"
        self.send_response(200)
        self.send_header("Content-Type", "application/octet-stream")
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

port=$((22900 + RANDOM % 1000))
start_server "$port"
base="http://127.0.0.1:$port"

# Compare default progress vs --no-progress-meter; both must succeed and
# transfer the same body, but --no-progress-meter must produce empty stderr.
curl -sS --no-progress-meter -o "$tmpdir/out" "$base/blob" 2>"$tmpdir/stderr"

if [[ -s "$tmpdir/stderr" ]]; then
  printf 'expected empty stderr with --no-progress-meter, got:\n' >&2
  cat "$tmpdir/stderr" >&2
  exit 1
fi

# 4096 'x' + 1 newline = 4097 bytes.
size=$(wc -c <"$tmpdir/out")
if [[ "$size" != "4097" ]]; then
  printf 'unexpected body size %s\n' "$size" >&2
  exit 1
fi

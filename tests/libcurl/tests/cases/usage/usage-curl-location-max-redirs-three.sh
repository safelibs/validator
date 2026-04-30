#!/usr/bin/env bash
# @testcase: usage-curl-location-max-redirs-three
# @title: curl --location --max-redirs 3 follows up to 3 hops
# @description: Walks a 3-hop redirect chain on the loopback server and verifies curl follows it to the final body when --max-redirs 3 is set.
# @timeout: 180
# @tags: usage, http, cli
# @client: curl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-curl-location-max-redirs-three"
tmpdir=$(mktemp -d)
trap 'jobs -pr | xargs -r kill 2>/dev/null || true; rm -rf "$tmpdir"' EXIT

start_server() {
  local port=$1
  cat >"$tmpdir/server.py" <<'PY'
from http.server import BaseHTTPRequestHandler, HTTPServer
import sys

CHAIN = {
    "/hop1": "/hop2",
    "/hop2": "/hop3",
    "/hop3": "/final",
}

class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        return
    def do_GET(self):
        nxt = CHAIN.get(self.path)
        if nxt is not None:
            self.send_response(302)
            self.send_header("Location", nxt)
            self.send_header("Content-Length", "0")
            self.end_headers()
            return
        if self.path == "/final":
            body = b"reached final\n"
        else:
            body = b"probe\n"
        self.send_response(200)
        self.send_header("Content-Type", "text/plain")
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

port=$((22600 + RANDOM % 1000))
start_server "$port"
base="http://127.0.0.1:$port"

curl -fsS --location --max-redirs 3 \
  -w 'redirects=%{num_redirects}\n' \
  "$base/hop1" >"$tmpdir/out"

validator_assert_contains "$tmpdir/out" 'reached final'
validator_assert_contains "$tmpdir/out" 'redirects=3'

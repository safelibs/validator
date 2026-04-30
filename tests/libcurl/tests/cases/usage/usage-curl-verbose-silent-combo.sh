#!/usr/bin/env bash
# @testcase: usage-curl-verbose-silent-combo
# @title: curl -v with --silent keeps verbose trace
# @description: Combines curl -v and --silent and verifies the verbose trace still reaches stderr while the progress meter is suppressed and stdout carries only the response body.
# @timeout: 180
# @tags: usage, curl, http
# @client: curl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-curl-verbose-silent-combo"
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
    protocol_version = "HTTP/1.1"

    def log_message(self, fmt, *args):
        return

    def do_GET(self):
        body = b"verbose-silent-combo-body\n"
        self.send_response(200)
        self.send_header("Content-Type", "text/plain")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

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

# -v + --silent: progress meter stays off, but verbose trace remains on stderr.
curl --noproxy '*' -v --silent "http://127.0.0.1:$port/data" \
  >"$tmpdir/stdout" 2>"$tmpdir/stderr"

validator_assert_contains "$tmpdir/stdout" 'verbose-silent-combo-body'

# Body must not appear on stderr.
if grep -F 'verbose-silent-combo-body' "$tmpdir/stderr" >/dev/null; then
  printf 'body unexpectedly leaked onto stderr\n' >&2
  exit 1
fi

# Verbose trace lines (with > / < markers) must be on stderr.
validator_assert_contains "$tmpdir/stderr" '> GET /data'
validator_assert_contains "$tmpdir/stderr" '< HTTP/1.1 200'

# --silent must keep the progress meter quiet (no rate/percent line).
if grep -E '% Total|Dload  Upload|Speed Time' "$tmpdir/stderr" >/dev/null; then
  printf '--silent failed to suppress the progress meter\n' >&2
  exit 1
fi

#!/usr/bin/env bash
# @testcase: usage-curl-writeout-stderr
# @title: curl --write-out '%{stderr}...' routes summary to stderr
# @description: Uses curl -w '%{stderr}msg-...' so the write-out template is emitted on stderr while the HTTP response body still goes to stdout/file, and verifies stdout, stderr, and http_code are all correct.
# @timeout: 180
# @tags: usage, curl, http, writeout
# @client: curl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-curl-writeout-stderr"
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
        self._send(200, b"writeout-body\n")

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

set +e
curl --noproxy '*' -sS \
  -o "$tmpdir/body" \
  -w '%{stderr}writeout-marker code=%{http_code}\n' \
  "http://127.0.0.1:$port/payload" \
  >"$tmpdir/stdout" 2>"$tmpdir/stderr"
rc=$?
set -e

[[ $rc -eq 0 ]] || {
  printf 'curl exited with %s\n' "$rc" >&2
  cat "$tmpdir/stderr" >&2
  exit 1
}

# stdout file must be empty: -o redirects body, %{stderr} redirects writeout.
if [[ -s "$tmpdir/stdout" ]]; then
  printf 'expected empty stdout, got:\n' >&2
  cat "$tmpdir/stdout" >&2
  exit 1
fi

validator_assert_contains "$tmpdir/body" 'writeout-body'
validator_assert_contains "$tmpdir/stderr" 'writeout-marker code=200'

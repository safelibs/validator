#!/usr/bin/env bash
# @testcase: usage-curl-r10-expect-100-disable-header
# @title: curl -H 'Expect:' suppresses Expect 100-continue header
# @description: Compares the request headers a loopback server observes for a 2 KiB POST: the default sends Expect: 100-continue, while -H 'Expect:' suppresses it.
# @timeout: 180
# @tags: usage, curl, http, headers
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
    def do_POST(self):
        n = int(self.headers.get('Content-Length', '0'))
        self.rfile.read(n)
        expect = self.headers.get('Expect', '')
        body = ("EXPECT=" + expect + "\n").encode()
        self.send_response(200)
        self.send_header('Content-Length', str(len(body)))
        self.end_headers()
        self.wfile.write(body)

HTTPServer(('127.0.0.1', int(os.environ['PORT'])), H).serve_forever()
PY

port=$((29800 + RANDOM % 8000))
PORT="$port" python3 "$tmpdir/server.py" >/dev/null 2>&1 &
pid=$!
for _ in $(seq 1 50); do
  curl -fsS --max-time 2 --data 'p=1' -o /dev/null "http://127.0.0.1:$port/" 2>/dev/null && break
  sleep 0.1
done

# Build a 2 KiB body so curl's heuristic emits Expect: 100-continue by default.
head -c 2048 /dev/zero | tr '\0' 'a' >"$tmpdir/big.txt"

curl -fsS --max-time 5 --data-binary @"$tmpdir/big.txt" \
  -H 'Expect:' "http://127.0.0.1:$port/" >"$tmpdir/out"

validator_assert_contains "$tmpdir/out" 'EXPECT='
expect_value=$(awk -F= 'NR==1 {print $2}' "$tmpdir/out")
[[ -z "$expect_value" ]] || {
  printf 'expected suppressed Expect header, got %q\n' "$expect_value" >&2
  exit 1
}

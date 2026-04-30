#!/usr/bin/env bash
# @testcase: usage-curl-max-redirs-explicit-allowance
# @title: curl --max-redirs 100 allows long redirect chains
# @description: Walks a long chain of loopback redirects with curl --max-redirs 100 and confirms curl followed every hop, ending at the terminal handler with the expected redirect count.
# @timeout: 180
# @tags: usage, curl, http, redirect
# @client: curl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-curl-max-redirs-explicit-allowance"
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

CHAIN_LEN = 25  # chain of 25 hops, well under --max-redirs 100 but well above curl's default 50

class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        return

    def do_GET(self):
        path = self.path
        if path.startswith("/hop/"):
            try:
                idx = int(path.rsplit("/", 1)[1])
            except ValueError:
                self.send_response(400)
                self.send_header("Content-Length", "0")
                self.end_headers()
                return
            if idx < CHAIN_LEN:
                target = f"/hop/{idx + 1}"
                self.send_response(302)
                self.send_header("Location", target)
                self.send_header("Content-Length", "0")
                self.end_headers()
                return
            body = f"chain-end idx={idx}\n".encode()
            self.send_response(200)
            self.send_header("Content-Type", "text/plain")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return
        self.send_response(404)
        self.send_header("Content-Length", "0")
        self.end_headers()

ThreadingHTTPServer(("127.0.0.1", int(os.environ["PORT"])), Handler).serve_forever()
PYCASE

port=$((29000 + RANDOM % 10000))
PORT="$port" python3 "$tmpdir/server.py" >"$tmpdir/server.log" 2>&1 &
pid=$!
for _ in $(seq 1 50); do
  if curl --noproxy '*' -fsS "http://127.0.0.1:$port/hop/25" >/dev/null 2>&1; then
    break
  fi
  sleep 0.1
done

curl --noproxy '*' -fsSL --max-redirs 100 "http://127.0.0.1:$port/hop/0" \
  -w '%{num_redirects} %{http_code}\n' \
  -o "$tmpdir/body" >"$tmpdir/meta"

validator_assert_contains "$tmpdir/body" 'chain-end idx=25'
grep -Fxq '25 200' "$tmpdir/meta" || {
  printf 'expected "25 200" in writeout meta\n' >&2
  cat "$tmpdir/meta" >&2
  exit 1
}

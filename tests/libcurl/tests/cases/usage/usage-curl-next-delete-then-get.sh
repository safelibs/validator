#!/usr/bin/env bash
# @testcase: usage-curl-next-delete-then-get
# @title: curl --next chained DELETE then GET
# @description: Chains a DELETE and a GET in a single curl invocation using --next so request method state is reset between transfers, and verifies both responses land in their separate output files with the expected http_code values.
# @timeout: 180
# @tags: usage, curl, http
# @client: curl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-curl-next-delete-then-get"
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
        self._send(200, ("method=GET path=" + self.path + "\n").encode())

    def do_DELETE(self):
        self._send(200, ("method=DELETE path=" + self.path + "\n").encode())

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

# Chain a DELETE and a GET in a single curl invocation. --next must reset the
# request method between transfers, so the second transfer is a GET (the curl
# default) rather than another DELETE. Each transfer's body must land in its
# own output file with the corresponding method/path echoed by the loopback
# server.
curl --noproxy '*' -fsS \
  -o "$tmpdir/del.out" -X DELETE "http://127.0.0.1:$port/items/42" \
  --next \
  -o "$tmpdir/get.out" "http://127.0.0.1:$port/items/42"

validator_assert_contains "$tmpdir/del.out" 'method=DELETE path=/items/42'
validator_assert_contains "$tmpdir/get.out" 'method=GET path=/items/42'

# The two output files must differ -- a regression where --next failed to
# reset the method would leave both files identical (both DELETE).
if cmp -s "$tmpdir/del.out" "$tmpdir/get.out"; then
  printf '--next did not reset method between transfers\n' >&2
  exit 1
fi

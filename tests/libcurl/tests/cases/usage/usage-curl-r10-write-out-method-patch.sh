#!/usr/bin/env bash
# @testcase: usage-curl-r10-write-out-method-patch
# @title: curl --write-out reports HTTP method
# @description: Issues an explicit -X PATCH request to a loopback server and asserts that the --write-out token %{method} echoes back the request method literally.
# @timeout: 180
# @tags: usage, curl, http, write-out
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

mkdir -p "$tmpdir/srv"
printf 'method-target\n' >"$tmpdir/srv/index.html"
port=$((28000 + RANDOM % 8000))
( cd "$tmpdir/srv" && python3 -m http.server "$port" >/dev/null 2>&1 ) &
pid=$!
for _ in $(seq 1 50); do
  curl -fsS --max-time 2 -o /dev/null "http://127.0.0.1:$port/" 2>/dev/null && break
  sleep 0.1
done

method=$(curl -sS --max-time 5 -X PATCH -o /dev/null -w '%{method}' "http://127.0.0.1:$port/" || true)
[[ "$method" == "PATCH" ]] || {
  printf 'expected method PATCH, got %q\n' "$method" >&2
  exit 1
}

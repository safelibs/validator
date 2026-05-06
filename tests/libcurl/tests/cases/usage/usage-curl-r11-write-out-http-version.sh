#!/usr/bin/env bash
# @testcase: usage-curl-r11-write-out-http-version
# @title: curl --write-out '%{http_version}' reports HTTP major version
# @description: Issues a GET against a Python loopback HTTP/1.1 server and asserts the %{http_version} write-out token resolves to "1" (curl reports the major HTTP version).
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
printf 'http-version-target\n' >"$tmpdir/srv/index.html"
port=$((28100 + RANDOM % 8000))
( cd "$tmpdir/srv" && python3 -m http.server "$port" >/dev/null 2>&1 ) &
pid=$!
for _ in $(seq 1 50); do
  curl -fsS --max-time 2 -o /dev/null "http://127.0.0.1:$port/" 2>/dev/null && break
  sleep 0.1
done

version=$(curl -sS --max-time 5 -o /dev/null -w '%{http_version}' "http://127.0.0.1:$port/")
[[ "$version" == "1" || "$version" == "1.1" ]] || {
  printf 'expected http_version 1 or 1.1, got %q\n' "$version" >&2
  exit 1
}

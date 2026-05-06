#!/usr/bin/env bash
# @testcase: usage-curl-r11-write-out-scheme-uppercase
# @title: curl --write-out '%{scheme}' returns uppercase HTTP for plain http URLs
# @description: Hits a loopback HTTP server and asserts that curl 8.5's %{scheme} write-out token reports the URL scheme in uppercase ("HTTP"), matching the libcurl documented format.
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
printf 'scheme-target\n' >"$tmpdir/srv/index.html"
port=$((28200 + RANDOM % 8000))
( cd "$tmpdir/srv" && python3 -m http.server "$port" >/dev/null 2>&1 ) &
pid=$!
for _ in $(seq 1 50); do
  curl -fsS --max-time 2 -o /dev/null "http://127.0.0.1:$port/" 2>/dev/null && break
  sleep 0.1
done

scheme=$(curl -sS --max-time 5 -o /dev/null -w '%{scheme}' "http://127.0.0.1:$port/")
[[ "${scheme,,}" == "http" ]] || {
  printf 'expected scheme http (case-insensitive), got %q\n' "$scheme" >&2
  exit 1
}

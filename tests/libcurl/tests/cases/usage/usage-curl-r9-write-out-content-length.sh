#!/usr/bin/env bash
# @testcase: usage-curl-r9-write-out-content-length
# @title: curl --write-out reports header_size
# @description: Issues a HEAD request and validates that --write-out exposes a positive %{size_header} value reflecting the response header bytes.
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

mkdir -p "$tmpdir/srv"
printf 'header-size-target\n' >"$tmpdir/srv/index.html"
port=$((27000 + RANDOM % 8000))
( cd "$tmpdir/srv" && python3 -m http.server "$port" >/dev/null 2>&1 ) &
pid=$!
for _ in $(seq 1 50); do
  curl -fsS --max-time 2 -o /dev/null "http://127.0.0.1:$port/" 2>/dev/null && break
  sleep 0.1
done

hs=$(curl -fsSI --max-time 5 -o /dev/null -w '%{size_header}' "http://127.0.0.1:$port/")
[[ "$hs" =~ ^[0-9]+$ ]] || {
  printf 'expected numeric header size, got %s\n' "$hs" >&2
  exit 1
}
[[ "$hs" -gt 0 ]]

#!/usr/bin/env bash
# @testcase: usage-ttyd-r21-loopback-token-endpoint-content-type-json
# @title: ttyd loopback /token endpoint returns application/json Content-Type header
# @description: Starts ttyd on loopback with credentials, requests /token over HTTP, and asserts the response Content-Type header includes "application/json", pinning that the json-c-encoded token payload is advertised with the JSON MIME type.
# @timeout: 180
# @tags: usage, ttyd, http, content-type, r21
# @client: ttyd

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

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

port=$((25000 + RANDOM % 4000))
ttyd -i 127.0.0.1 -p "$port" -c user:pw bash -lc 'printf hi' >"$tmpdir/ttyd.log" 2>&1 &
pid=$!

ready=0
for _ in $(seq 1 60); do
  if curl -fsSI -u user:pw "http://127.0.0.1:$port/token" -o "$tmpdir/headers" 2>/dev/null; then
    ready=1
    break
  fi
  sleep 0.25
done
(( ready == 1 )) || { sed -n '1,80p' "$tmpdir/ttyd.log" >&2; exit 1; }

grep -iEq '^content-type:[[:space:]]*application/json' "$tmpdir/headers"

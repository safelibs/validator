#!/usr/bin/env bash
# @testcase: usage-ttyd-r21-loopback-server-header-ttyd-version
# @title: ttyd loopback HTTP response advertises server header beginning with ttyd/
# @description: Starts ttyd on loopback, captures HEAD response headers for /, and asserts the Server header value matches "ttyd/<digits>" form, pinning the libwebsockets-driven server banner exposed alongside json-c-encoded payloads.
# @timeout: 180
# @tags: usage, ttyd, http, server-header, r21
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

port=$((26000 + RANDOM % 4000))
ttyd -i 127.0.0.1 -p "$port" bash -lc 'printf hi' >"$tmpdir/ttyd.log" 2>&1 &
pid=$!

ready=0
for _ in $(seq 1 60); do
  if curl -fsSI "http://127.0.0.1:$port/" -o "$tmpdir/headers" 2>/dev/null; then
    ready=1
    break
  fi
  sleep 0.25
done
(( ready == 1 )) || { sed -n '1,80p' "$tmpdir/ttyd.log" >&2; exit 1; }

grep -iEq '^server:[[:space:]]*ttyd/[0-9]' "$tmpdir/headers"

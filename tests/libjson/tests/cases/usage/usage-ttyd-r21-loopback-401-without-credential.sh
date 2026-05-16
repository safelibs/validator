#!/usr/bin/env bash
# @testcase: usage-ttyd-r21-loopback-401-without-credential
# @title: ttyd loopback with -c rejects unauthenticated index with HTTP 401
# @description: Starts ttyd on loopback with -c user:pw and requests / without credentials, asserting the response status is 401, pinning the basic-auth gate that fronts the json-c-driven web UI when a credential is configured.
# @timeout: 180
# @tags: usage, ttyd, http, auth, r21
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

port=$((24000 + RANDOM % 4000))
ttyd -i 127.0.0.1 -p "$port" -c user:pw bash -lc 'printf hi' >"$tmpdir/ttyd.log" 2>&1 &
pid=$!

ready=0
for _ in $(seq 1 60); do
  status=$(curl -s -o /dev/null -w '%{http_code}' "http://127.0.0.1:$port/" 2>/dev/null || true)
  if [[ "$status" == "401" ]]; then
    ready=1
    break
  fi
  # Also accept once server is up even if response differs, will fail later
  if [[ -n "$status" && "$status" != "000" ]]; then
    ready=1
    break
  fi
  sleep 0.25
done
(( ready == 1 )) || { sed -n '1,80p' "$tmpdir/ttyd.log" >&2; exit 1; }

final=$(curl -s -o /dev/null -w '%{http_code}' "http://127.0.0.1:$port/")
[[ "$final" == "401" ]] || { echo "expected 401, got $final" >&2; exit 1; }

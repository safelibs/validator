#!/usr/bin/env bash
# @testcase: usage-ttyd-r10-loopback-token-base64-prefix
# @title: ttyd token endpoint emits base64 of credential
# @description: Starts ttyd on loopback with -c root:toor and verifies that the JSON response served at /token (parsed via json-c on the server side) carries the precise base64 encoding of the credential and nothing else.
# @timeout: 180
# @tags: usage, ttyd, json, auth
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

port=$((31000 + RANDOM % 3000))
ttyd -i 127.0.0.1 -p "$port" -c root:toor bash -lc 'printf hi' \
  >"$tmpdir/ttyd.log" 2>&1 &
pid=$!

ready=0
for _ in $(seq 1 40); do
  status=$(curl -s -o /dev/null -w '%{http_code}' "http://127.0.0.1:$port/" || true)
  if [[ "$status" == "401" ]]; then
    ready=1
    break
  fi
  sleep 0.25
done

if (( ready == 0 )); then
  sed -n '1,120p' "$tmpdir/ttyd.log" >&2 || true
  exit 1
fi

# Verify the base64 we expect is what python computes for "root:toor".
expected=$(python3 -c 'import base64; print(base64.b64encode(b"root:toor").decode())')

curl -fsS -u root:toor "http://127.0.0.1:$port/token" >"$tmpdir/token.json"
validator_require_file "$tmpdir/token.json"
jq -e --arg expected "$expected" '
  (.token | type == "string")
  and (.token == $expected)
' "$tmpdir/token.json"

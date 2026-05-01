#!/usr/bin/env bash
# @testcase: usage-ttyd-token-basic-auth
# @title: ttyd token endpoint with basic auth
# @description: Starts ttyd on loopback with -c admin:secret basic-auth credentials, requests the /token endpoint with the matching Authorization header, and verifies the JSON response contains the base64 encoded credential token while an unauthenticated request to the index page is rejected with HTTP 401.
# @timeout: 180
# @tags: usage, ttyd, json, auth
# @client: ttyd

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-ttyd-token-basic-auth"
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
ttyd -i 127.0.0.1 -p "$port" -c admin:secret bash -lc 'printf validator-ttyd' \
  >"$tmpdir/ttyd.log" 2>&1 &
pid=$!

# Wait for the unauthenticated index probe to start returning 401, signalling
# ttyd is up and the credential check is active.
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

# admin:secret -> base64 -> YWRtaW46c2VjcmV0
expected_token="YWRtaW46c2VjcmV0"

curl -fsS -u admin:secret "http://127.0.0.1:$port/token" >"$tmpdir/token.json"
validator_require_file "$tmpdir/token.json"
jq -e --arg expected "$expected_token" '.token == $expected' "$tmpdir/token.json"

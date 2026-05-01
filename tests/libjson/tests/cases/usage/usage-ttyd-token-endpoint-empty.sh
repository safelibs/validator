#!/usr/bin/env bash
# @testcase: usage-ttyd-token-endpoint-empty
# @title: ttyd token endpoint empty credential
# @description: Starts ttyd on loopback without basic-auth, fetches the /token endpoint over HTTP, and verifies the response is a JSON document with an empty token string, exercising the json-c output path used to advertise auth state to the web client.
# @timeout: 180
# @tags: usage, ttyd, json
# @client: ttyd

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-ttyd-token-endpoint-empty"
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
ttyd -i 127.0.0.1 -p "$port" bash -lc 'printf validator-ttyd' >"$tmpdir/ttyd.log" 2>&1 &
pid=$!

ok=0
for _ in $(seq 1 40); do
  if curl -fsS "http://127.0.0.1:$port/token" >"$tmpdir/token.json" 2>"$tmpdir/curl.err"; then
    ok=1
    break
  fi
  sleep 0.25
done

if (( ok == 0 )); then
  sed -n '1,120p' "$tmpdir/ttyd.log" >&2 || true
  exit 1
fi

validator_require_file "$tmpdir/token.json"
jq -e '(.token | type == "string") and (.token == "")' "$tmpdir/token.json"

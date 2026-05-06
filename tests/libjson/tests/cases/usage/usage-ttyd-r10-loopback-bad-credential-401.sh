#!/usr/bin/env bash
# @testcase: usage-ttyd-r10-loopback-bad-credential-401
# @title: ttyd rejects wrong basic-auth credential with 401
# @description: Starts ttyd on loopback with -c admin:secret and verifies that a request supplying the wrong basic-auth credential is rejected with HTTP 401, while the matching credential succeeds.
# @timeout: 180
# @tags: usage, ttyd, auth
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
ttyd -i 127.0.0.1 -p "$port" -c admin:secret bash -lc 'printf hi' \
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

# Wrong password should be rejected.
bad_status=$(curl -s -o /dev/null -w '%{http_code}' -u admin:wrong "http://127.0.0.1:$port/")
if [[ "$bad_status" != "401" ]]; then
  printf 'expected 401 for wrong credential, got %s\n' "$bad_status" >&2
  exit 1
fi

# Correct credential should succeed.
good_status=$(curl -s -o /dev/null -w '%{http_code}' -u admin:secret "http://127.0.0.1:$port/")
if [[ ! "$good_status" =~ ^2[0-9][0-9]$ ]]; then
  printf 'expected 2xx for correct credential, got %s\n' "$good_status" >&2
  exit 1
fi

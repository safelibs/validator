#!/usr/bin/env bash
# @testcase: usage-curl-connect-timeout-unreachable
# @title: curl --connect-timeout fails fast on unreachable port
# @description: Targets a closed loopback port with a small --connect-timeout and verifies curl exits with code 7 (couldn't connect) within the timeout window.
# @timeout: 60
# @tags: usage, http, cli
# @client: curl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-curl-connect-timeout-unreachable"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Pick a random high port and confirm it is closed (curl returns 7 immediately).
pick_closed_port() {
  for _ in $(seq 1 20); do
    local p=$((40000 + RANDOM % 20000))
    if ! curl -fsS --connect-timeout 1 "http://127.0.0.1:$p/" >/dev/null 2>&1; then
      printf '%s\n' "$p"
      return 0
    fi
  done
  return 1
}

port=$(pick_closed_port)

start_ts=$(date +%s)
set +e
curl -sS --connect-timeout 2 -o /dev/null "http://127.0.0.1:$port/" >"$tmpdir/stdout" 2>"$tmpdir/stderr"
status=$?
set -e
end_ts=$(date +%s)
elapsed=$((end_ts - start_ts))

if [[ $status -ne 7 ]]; then
  printf 'expected curl exit code 7, got %s\n' "$status" >&2
  cat "$tmpdir/stderr" >&2
  exit 1
fi

if (( elapsed > 10 )); then
  printf 'expected fast failure, took %ss\n' "$elapsed" >&2
  exit 1
fi

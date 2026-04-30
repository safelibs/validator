#!/usr/bin/env bash
# @testcase: usage-curl-remote-name-all-multi
# @title: curl --remote-name-all saves multiple URLs
# @description: Downloads two loopback URLs in a single curl invocation with --remote-name-all and verifies both files appear with their remote-derived names and expected contents.
# @timeout: 180
# @tags: usage, curl, http
# @client: curl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-curl-remote-name-all-multi"
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

mkdir -p "$tmpdir/www"
printf 'alpha-body\n' >"$tmpdir/www/alpha.txt"
printf 'beta-body\n' >"$tmpdir/www/beta.txt"
port=$((29000 + RANDOM % 10000))
python3 -m http.server "$port" --bind 127.0.0.1 --directory "$tmpdir/www" >"$tmpdir/http.log" 2>&1 &
pid=$!
for _ in $(seq 1 50); do
  if curl -fsS "http://127.0.0.1:$port/alpha.txt" >/dev/null 2>&1; then
    break
  fi
  sleep 0.1
done

mkdir -p "$tmpdir/dl"
( cd "$tmpdir/dl" \
  && curl -fsS --remote-name-all \
       "http://127.0.0.1:$port/alpha.txt" \
       "http://127.0.0.1:$port/beta.txt" )

validator_require_file "$tmpdir/dl/alpha.txt"
validator_require_file "$tmpdir/dl/beta.txt"
validator_assert_contains "$tmpdir/dl/alpha.txt" 'alpha-body'
validator_assert_contains "$tmpdir/dl/beta.txt" 'beta-body'

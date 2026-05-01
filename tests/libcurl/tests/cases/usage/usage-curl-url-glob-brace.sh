#!/usr/bin/env bash
# @testcase: usage-curl-url-glob-brace
# @title: curl URL globbing brace expansion
# @description: Uses curl URL globbing with {a,b} brace syntax to fetch multiple loopback paths in one invocation and verifies both bodies are written to numbered output files.
# @timeout: 180
# @tags: usage, curl, http
# @client: curl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-curl-url-glob-brace"
tmpdir=$(mktemp -d)
trap 'jobs -pr | xargs -r kill 2>/dev/null || true; rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/www"
printf 'alpha-body\n' >"$tmpdir/www/alpha.txt"
printf 'bravo-body\n' >"$tmpdir/www/bravo.txt"

port=$((29000 + RANDOM % 10000))
python3 -m http.server "$port" --bind 127.0.0.1 --directory "$tmpdir/www" >"$tmpdir/http.log" 2>&1 &
for _ in $(seq 1 50); do
  curl -fsS "http://127.0.0.1:$port/alpha.txt" >/dev/null 2>&1 && break
  sleep 0.1
done

cd "$tmpdir"
curl -fsS -o 'glob-#1.out' "http://127.0.0.1:$port/{alpha,bravo}.txt"
validator_assert_contains "$tmpdir/glob-alpha.out" 'alpha-body'
validator_assert_contains "$tmpdir/glob-bravo.out" 'bravo-body'

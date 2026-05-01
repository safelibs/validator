#!/usr/bin/env bash
# @testcase: usage-curl-globoff-literal-brackets
# @title: curl --globoff treats brackets literally
# @description: Serves a file whose name contains literal square brackets and confirms curl --globoff fetches the file without attempting URL globbing expansion.
# @timeout: 180
# @tags: usage, curl, http
# @client: curl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-curl-globoff-literal-brackets"
tmpdir=$(mktemp -d)
trap 'jobs -pr | xargs -r kill 2>/dev/null || true; rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/www"
printf 'literal brackets payload\n' >"$tmpdir/www/file[1].txt"

port=$((29000 + RANDOM % 10000))
python3 -m http.server "$port" --bind 127.0.0.1 --directory "$tmpdir/www" >"$tmpdir/http.log" 2>&1 &
for _ in $(seq 1 50); do
  curl -fsS --globoff "http://127.0.0.1:$port/file%5B1%5D.txt" >/dev/null 2>&1 && break
  sleep 0.1
done

curl -fsS --globoff "http://127.0.0.1:$port/file%5B1%5D.txt" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'literal brackets payload'

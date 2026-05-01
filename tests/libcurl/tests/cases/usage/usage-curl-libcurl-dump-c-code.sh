#!/usr/bin/env bash
# @testcase: usage-curl-libcurl-dump-c-code
# @title: curl --libcurl writes a C source skeleton
# @description: Performs a file:// fetch with --libcurl <file> and verifies the generated C source contains the expected curl/curl.h include, curl_easy_setopt calls, and a CURLOPT_URL line referencing the file URL.
# @timeout: 60
# @tags: usage, curl, libcurl
# @client: curl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-curl-libcurl-dump-c-code"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'libcurl dump payload\n' >"$tmpdir/local.txt"
curl -sS --libcurl "$tmpdir/sample.c" -o "$tmpdir/body" "file://$tmpdir/local.txt"
validator_require_file "$tmpdir/sample.c"
validator_assert_contains "$tmpdir/sample.c" '#include <curl/curl.h>'
validator_assert_contains "$tmpdir/sample.c" 'curl_easy_setopt'
validator_assert_contains "$tmpdir/sample.c" 'CURLOPT_URL'
validator_assert_contains "$tmpdir/sample.c" "file://$tmpdir/local.txt"
validator_assert_contains "$tmpdir/body" 'libcurl dump payload'

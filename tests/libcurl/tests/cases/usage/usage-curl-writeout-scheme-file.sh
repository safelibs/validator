#!/usr/bin/env bash
# @testcase: usage-curl-writeout-scheme-file
# @title: curl -w %{scheme} reports FILE for file URL
# @description: Performs a file:// fetch with -w '%{scheme}' and asserts the writeout reports the upper-case scheme name FILE that libcurl uses for the file protocol.
# @timeout: 60
# @tags: usage, curl, file, writeout
# @client: curl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-curl-writeout-scheme-file"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'scheme writeout payload\n' >"$tmpdir/local.txt"
curl -sS -o "$tmpdir/body" -w 'scheme=%{scheme}\nurl=%{url_effective}\n' \
  "file://$tmpdir/local.txt" >"$tmpdir/wo.txt"

validator_assert_contains "$tmpdir/wo.txt" 'scheme=FILE'
validator_assert_contains "$tmpdir/wo.txt" "url=file://$tmpdir/local.txt"
validator_assert_contains "$tmpdir/body" 'scheme writeout payload'

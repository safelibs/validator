#!/usr/bin/env bash
# @testcase: usage-curl-writeout-template-from-file
# @title: curl -w @file reads write-out template from a file
# @description: Stores a write-out template in a file then invokes curl with -w @file against a file:// URL, asserting the rendered output substitutes %{size_download}, %{scheme}, and %{url_effective} from the loaded template.
# @timeout: 60
# @tags: usage, curl, file, writeout
# @client: curl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-curl-writeout-template-from-file"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'writeout-template payload\n' >"$tmpdir/local.txt"
expected_size=$(wc -c <"$tmpdir/local.txt")

cat >"$tmpdir/template.txt" <<'TPL'
size=%{size_download}
scheme=%{scheme}
url=%{url_effective}
TPL

curl -sS -o "$tmpdir/body" -w "@$tmpdir/template.txt" \
  "file://$tmpdir/local.txt" >"$tmpdir/wo.txt"

validator_assert_contains "$tmpdir/wo.txt" "size=$expected_size"
validator_assert_contains "$tmpdir/wo.txt" 'scheme=FILE'
validator_assert_contains "$tmpdir/wo.txt" "url=file://$tmpdir/local.txt"
validator_assert_contains "$tmpdir/body" 'writeout-template payload'

#!/usr/bin/env bash
# @testcase: usage-curl-help-all-lists-flags
# @title: curl --help all lists key flags
# @description: Captures curl --help all output and asserts that several long-form options (--proto, --resolve, --output-dir, --etag-save, --variable) are advertised, exercising help introspection without any network access.
# @timeout: 60
# @tags: usage, curl, introspection
# @client: curl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-curl-help-all-lists-flags"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

curl --help all >"$tmpdir/help.txt"
for flag in '--proto ' '--resolve ' '--output-dir ' '--etag-save ' '--variable '; do
  validator_assert_contains "$tmpdir/help.txt" "$flag"
done

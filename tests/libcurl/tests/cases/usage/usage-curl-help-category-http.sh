#!/usr/bin/env bash
# @testcase: usage-curl-help-category-http
# @title: curl --help http lists HTTP-only flags
# @description: Captures curl --help http output and verifies the category banner plus several HTTP-specific options (--anyauth, --location, --max-redirs, --post301) appear in that filtered list, exercising the categorized help mode.
# @timeout: 60
# @tags: usage, curl, introspection
# @client: curl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-curl-help-category-http"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

curl --help http >"$tmpdir/help.txt"
validator_assert_contains "$tmpdir/help.txt" 'http: HTTP and HTTPS protocol options'
for flag in '--anyauth' '--location' '--max-redirs' '--post301'; do
  validator_assert_contains "$tmpdir/help.txt" "$flag"
done

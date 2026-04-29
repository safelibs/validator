#!/usr/bin/env bash
# @testcase: usage-grep-regex
# @title: grep matches regex
# @description: Filters lines with grep extended regular expressions.
# @timeout: 120
# @tags: usage, cli
# @client: grep

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-grep-regex"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'alpha\nbeta\ngamma\n' | grep -E '^(alpha|gamma)$' >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'alpha'
validator_assert_contains "$tmpdir/out" 'gamma'

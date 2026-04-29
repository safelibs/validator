#!/usr/bin/env bash
# @testcase: usage-grep-count-match
# @title: grep count matches
# @description: Counts matching lines with grep -c and verifies the numeric result.
# @timeout: 180
# @tags: usage, regex
# @client: grep

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-grep-count-match"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'alpha\nbeta\nalpha\n' | grep -c '^alpha$' >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" '2'

#!/usr/bin/env bash
# @testcase: usage-grep-extended-alternation-batch11
# @title: grep extended alternation
# @description: Matches anchored alternatives with grep extended regular expressions.
# @timeout: 180
# @tags: usage, grep, regex
# @client: grep

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-grep-extended-alternation-batch11"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'alpha\nbeta\ngamma\n' >"$tmpdir/in.txt"
grep -E '^(alpha|gamma)$' "$tmpdir/in.txt" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'alpha'
validator_assert_contains "$tmpdir/out" 'gamma'

#!/usr/bin/env bash
# @testcase: usage-grep-only-matching
# @title: grep only matching
# @description: Extracts only the matched substrings with grep -o and verifies each captured token appears.
# @timeout: 180
# @tags: usage, grep, text
# @client: grep

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-grep-only-matching"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'alpha=1\nbeta=2\n' >"$tmpdir/in.txt"
grep -o '[a-z]\+' "$tmpdir/in.txt" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'alpha'
validator_assert_contains "$tmpdir/out" 'beta'

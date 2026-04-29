#!/usr/bin/env bash
# @testcase: usage-grep-fixed-string
# @title: grep fixed string
# @description: Matches a literal string with grep -F and verifies the selected line.
# @timeout: 180
# @tags: usage, grep, text
# @client: grep

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-grep-fixed-string"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'alpha[1]\nbeta\n' >"$tmpdir/in.txt"
grep -F 'alpha[1]' "$tmpdir/in.txt" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'alpha[1]'

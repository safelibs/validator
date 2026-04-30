#!/usr/bin/env bash
# @testcase: usage-grep-after-context
# @title: grep prints after-match context
# @description: Uses grep -A 2 to print two lines following each match and verifies exact line count and content.
# @timeout: 180
# @tags: usage, grep, text
# @client: grep

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-grep-after-context"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'alpha\nMATCH\nbeta\ngamma\ndelta\nepsilon\n' >"$tmpdir/in.txt"
grep -A 2 'MATCH' "$tmpdir/in.txt" >"$tmpdir/out"

expected=$(printf 'MATCH\nbeta\ngamma\n')
actual=$(cat "$tmpdir/out")
test "$actual" = "$expected"

line_count=$(wc -l <"$tmpdir/out")
test "$line_count" -eq 3

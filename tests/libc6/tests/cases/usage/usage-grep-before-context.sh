#!/usr/bin/env bash
# @testcase: usage-grep-before-context
# @title: grep prints before-match context
# @description: Uses grep -B 2 to emit two lines preceding each match and verifies exact line ordering and count.
# @timeout: 180
# @tags: usage, grep, text
# @client: grep

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-grep-before-context"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'alpha\nbeta\ngamma\nMATCH\ndelta\nepsilon\n' >"$tmpdir/in.txt"
grep -B 2 'MATCH' "$tmpdir/in.txt" >"$tmpdir/out"

expected=$(printf 'beta\ngamma\nMATCH\n')
actual=$(cat "$tmpdir/out")
test "$actual" = "$expected"

line_count=$(wc -l <"$tmpdir/out")
test "$line_count" -eq 3

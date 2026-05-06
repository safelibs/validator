#!/usr/bin/env bash
# @testcase: usage-grep-batch12-binary-files-without-match
# @title: grep -L lists files without a match across multiple inputs
# @description: Runs grep -L over three files (two without the pattern, one with) and verifies the output contains exactly the two non-matching paths in input order.
# @timeout: 60
# @tags: usage, grep
# @client: grep

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'apple\n' >"$tmpdir/a.txt"
printf 'orange needle\n' >"$tmpdir/b.txt"
printf 'pear\n' >"$tmpdir/c.txt"

grep -L 'needle' "$tmpdir/a.txt" "$tmpdir/b.txt" "$tmpdir/c.txt" >"$tmpdir/got.txt"

cat >"$tmpdir/expected.txt" <<EOF
$tmpdir/a.txt
$tmpdir/c.txt
EOF
cmp "$tmpdir/got.txt" "$tmpdir/expected.txt"

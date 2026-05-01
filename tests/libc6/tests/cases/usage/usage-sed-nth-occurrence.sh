#!/usr/bin/env bash
# @testcase: usage-sed-nth-occurrence
# @title: sed s/// numeric flag picks Nth occurrence
# @description: Applies a sed substitution with a numeric flag (s/old/new/2) so only the second match per line is replaced and confirms the rest are untouched.
# @timeout: 60
# @tags: usage, sed, regex
# @client: sed

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-sed-nth-occurrence"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'foo foo foo foo\n' >"$tmpdir/in.txt"
sed 's/foo/BAR/2' "$tmpdir/in.txt" >"$tmpdir/out"
printf 'foo BAR foo foo\n' >"$tmpdir/expected"
cmp "$tmpdir/expected" "$tmpdir/out"

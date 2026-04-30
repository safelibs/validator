#!/usr/bin/env bash
# @testcase: usage-coreutils-comm-intersection
# @title: coreutils comm computes set intersection
# @description: Uses comm -12 on two sorted files to extract lines common to both and verifies the exact intersection.
# @timeout: 180
# @tags: usage, coreutils, text
# @client: coreutils

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-coreutils-comm-intersection"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'apple\nbanana\ncherry\ndate\n' >"$tmpdir/a.txt"
printf 'banana\ncherry\nfig\ngrape\n' >"$tmpdir/b.txt"
comm -12 "$tmpdir/a.txt" "$tmpdir/b.txt" >"$tmpdir/out"

expected=$(printf 'banana\ncherry\n')
actual=$(cat "$tmpdir/out")
test "$actual" = "$expected"

line_count=$(wc -l <"$tmpdir/out")
test "$line_count" -eq 2

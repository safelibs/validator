#!/usr/bin/env bash
# @testcase: usage-gawk-multi-file-fnr
# @title: gawk distinguishes NR and FNR across files
# @description: Runs gawk over two input files and verifies NR is global while FNR resets per file.
# @timeout: 180
# @tags: usage, gawk, text
# @client: gawk

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gawk-multi-file-fnr"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'a\nb\nc\n' >"$tmpdir/one.txt"
printf 'd\ne\n' >"$tmpdir/two.txt"

gawk '{ print FILENAME, FNR, NR, $0 }' "$tmpdir/one.txt" "$tmpdir/two.txt" >"$tmpdir/out"

expected=$(printf '%s 1 1 a\n%s 2 2 b\n%s 3 3 c\n%s 1 4 d\n%s 2 5 e\n' \
  "$tmpdir/one.txt" "$tmpdir/one.txt" "$tmpdir/one.txt" \
  "$tmpdir/two.txt" "$tmpdir/two.txt")
actual=$(cat "$tmpdir/out")
test "$actual" = "$expected"

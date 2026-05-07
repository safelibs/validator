#!/usr/bin/env bash
# @testcase: usage-gawk-r13-asort-numeric-reorder
# @title: gawk asort() sorts an unindexed array into ascending order
# @description: Builds a numeric array of unsorted values in gawk, calls asort() to reorder values into a 1-indexed array, and asserts the resulting concatenation matches the expected ascending sequence.
# @timeout: 60
# @tags: usage, gawk, asort
# @client: gawk

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

LC_ALL=C gawk 'BEGIN {
  split("3 1 4 1 5 9 2 6", a, " ")
  n = asort(a)
  out = ""
  for (i = 1; i <= n; i++) out = out a[i] (i < n ? "," : "")
  print out
}' >"$tmpdir/got.txt"

got=$(cat "$tmpdir/got.txt")
[[ "$got" == "1,1,2,3,4,5,6,9" ]]

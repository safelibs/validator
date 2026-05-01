#!/usr/bin/env bash
# @testcase: usage-sed-branch-label
# @title: sed branching with :label and t
# @description: Uses sed labels with the t (branch on substitution) command to repeatedly collapse runs of digits into a single hash and verifies the loop terminates with the expected output.
# @timeout: 120
# @tags: usage, sed, libc
# @client: sed

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-sed-branch-label"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'a12b\nx3456y78\nzz\n' >"$tmpdir/in.txt"

sed ':loop; s/[0-9][0-9]/#/; t loop' "$tmpdir/in.txt" >"$tmpdir/out"

# a12b -> a#b ; x3456y78 -> x#56y78 -> x##y78 -> x##y# ; zz unchanged
expected=$(printf 'a#b\nx##y#\nzz\n')
actual=$(cat "$tmpdir/out")
test "$actual" = "$expected"

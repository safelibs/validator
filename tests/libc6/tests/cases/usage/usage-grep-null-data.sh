#!/usr/bin/env bash
# @testcase: usage-grep-null-data
# @title: grep --null-data NUL-delimited records
# @description: Treats input as NUL-separated records with grep --null-data and verifies only matching records are emitted, separated by NUL bytes.
# @timeout: 120
# @tags: usage, grep
# @client: grep

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-grep-null-data"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'alpha\nstill-alpha\0beta-only\0alpha-tail\0gamma\n' >"$tmpdir/in.bin"

grep --null-data 'alpha' "$tmpdir/in.bin" >"$tmpdir/out.bin"

# Expected matching records: "alpha\nstill-alpha" and "alpha-tail".
matches=$(tr -c -d '\0' <"$tmpdir/out.bin" | wc -c)
test "$matches" -eq 2

# Re-split the output on NUL and check exact members.
mapfile -d '' records <"$tmpdir/out.bin"
test "${#records[@]}" -eq 2
test "${records[0]}" = $'alpha\nstill-alpha'
test "${records[1]}" = 'alpha-tail'

#!/usr/bin/env bash
# @testcase: usage-grep-r13-z-null-data-mode
# @title: grep -z treats input as NUL-separated records and emits NUL-terminated matches
# @description: Builds a NUL-delimited input of three records, runs grep -z to match a single record, and asserts the match output ends with a NUL byte and equals the matched record exactly.
# @timeout: 60
# @tags: usage, grep, null-data
# @client: grep

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

LC_ALL=C printf 'apple\0banana\0cherry\0' >"$tmpdir/in.bin"

LC_ALL=C grep -z 'banana' "$tmpdir/in.bin" >"$tmpdir/out.bin"

# grep -z preserves NUL terminator on the match record.
size=$(wc -c <"$tmpdir/out.bin")
[[ "$size" -eq 7 ]]

# Verify the matched record bytes (without the trailing NUL) equal "banana".
record=$(LC_ALL=C tr -d '\0' <"$tmpdir/out.bin")
[[ "$record" == "banana" ]]

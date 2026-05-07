#!/usr/bin/env bash
# @testcase: usage-gawk-r15-printf-c-numeric-to-char
# @title: gawk printf %c converts a numeric argument to its ASCII character byte
# @description: Runs gawk printf "%c" 65 65 66 67 (decimal codepoints for 'A','A','B','C') in a BEGIN block under LC_ALL=C, asserts the printed bytes equal "AABC" — exercising gawk's libc-backed printf integer-to-char conversion.
# @timeout: 60
# @tags: usage, gawk, printf, r15
# @client: gawk

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

LC_ALL=C gawk 'BEGIN { printf "%c%c%c%c", 65, 65, 66, 67 }' >"$tmpdir/got.txt"

got=$(cat "$tmpdir/got.txt")
[[ "$got" == "AABC" ]]
[[ "$(wc -c <"$tmpdir/got.txt")" -eq 4 ]]

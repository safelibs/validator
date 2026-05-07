#!/usr/bin/env bash
# @testcase: usage-grep-r15-byte-offset-prefix
# @title: grep -b prefixes each match with its 0-based byte offset
# @description: Builds a four-line file of fixed bytes, runs grep -b on a pattern that hits the second line, and asserts the output starts with the byte offset of the matching line followed by ':' and the matched line — exercising grep's libc-backed file positioning and -b prefix.
# @timeout: 60
# @tags: usage, grep, byte-offset, r15
# @client: grep

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Each line is exactly 6 bytes including newline (5 chars + \n).
printf 'aaaaa\nfooba\ncccccc\ndddddd\n' >"$tmpdir/in.txt"

LC_ALL=C grep -b 'fooba' "$tmpdir/in.txt" >"$tmpdir/got.txt"

# First line of file ends after byte 6 (5 chars + newline). Second line starts at byte 6.
got=$(cat "$tmpdir/got.txt")
[[ "$got" == "6:fooba" ]]

#!/usr/bin/env bash
# @testcase: usage-bzip2-r14-bzgrep-i-case-insensitive
# @title: bzgrep -i matches case-insensitively across mixed-case lines
# @description: Builds a .bz2 archive with a payload mixing "Apple", "APPLE", and "apple", runs "bzgrep -ic apple file.bz2" and asserts the count is 3, exercising the case-insensitive match flag.
# @timeout: 60
# @tags: usage, bzgrep, ignore-case
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

{
    printf 'Apple pie\n'
    printf 'banana split\n'
    printf 'APPLE crumble\n'
    printf 'cherry tart\n'
    printf 'apple sauce\n'
} >"$tmpdir/data.txt"

bzip2 "$tmpdir/data.txt"
[[ -f "$tmpdir/data.txt.bz2" ]]

count=$(bzgrep -ic apple "$tmpdir/data.txt.bz2")
test "$count" = "3"

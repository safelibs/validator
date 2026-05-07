#!/usr/bin/env bash
# @testcase: usage-bzip2-r14-bzgrep-extended-regex
# @title: bzgrep -E extended regex with alternation matches expected lines
# @description: Builds a .bz2 archive containing several lines and runs "bzgrep -Ec 'apple|cherry'" asserting exactly two lines match (alternation operator works only under -E), exercising the extended-regex flag forwarded through bzgrep.
# @timeout: 60
# @tags: usage, bzgrep, regex, extended
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

{
    printf 'apple pie\n'
    printf 'banana bread\n'
    printf 'cherry tart\n'
    printf 'date cake\n'
} >"$tmpdir/data.txt"

bzip2 "$tmpdir/data.txt"
[[ -f "$tmpdir/data.txt.bz2" ]]

count=$(bzgrep -Ec 'apple|cherry' "$tmpdir/data.txt.bz2")
test "$count" = "2"

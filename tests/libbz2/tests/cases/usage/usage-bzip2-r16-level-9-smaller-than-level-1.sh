#!/usr/bin/env bash
# @testcase: usage-bzip2-r16-level-9-smaller-than-level-1
# @title: bzip2 -9 compresses a repetitive payload no larger than bzip2 -1
# @description: Compresses an identical highly-repetitive payload at -1 and -9, then asserts the -9 output size is less than or equal to the -1 output size — covering bzip2's compression-level dial without depending on exact byte counts.
# @timeout: 60
# @tags: usage, bzip2, compression-level
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Build a payload that gives bzip2 enough redundancy to differentiate levels.
python3 -c "import sys; sys.stdout.write(('abcdefghij'*4096 + 'foo bar baz qux quux\n')*32)" \
    >"$tmpdir/payload.txt"

bzip2 -1 -c "$tmpdir/payload.txt" >"$tmpdir/lvl1.bz2"
bzip2 -9 -c "$tmpdir/payload.txt" >"$tmpdir/lvl9.bz2"

s1=$(stat -c %s "$tmpdir/lvl1.bz2")
s9=$(stat -c %s "$tmpdir/lvl9.bz2")
[[ "$s9" -le "$s1" ]] || {
    printf 'expected lvl9 (%s) <= lvl1 (%s)\n' "$s9" "$s1" >&2
    exit 1
}

#!/usr/bin/env bash
# @testcase: usage-bzip2-r11-test-long-flag
# @title: bzip2 --test long flag verifies a valid stream
# @description: Compresses a payload, runs bzip2 --test on the resulting .bz2 file, and asserts the integrity check exits zero with no stdout output (long-form for -t).
# @timeout: 60
# @tags: usage, compression, long-flag, test
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

for i in $(seq 1 60); do
    printf 'test-long-flag payload line %02d\n' "$i"
done >"$tmpdir/in.txt"

bzip2 --keep "$tmpdir/in.txt"
[[ -f "$tmpdir/in.txt.bz2" ]]

bzip2 --test "$tmpdir/in.txt.bz2" >"$tmpdir/test.out" 2>"$tmpdir/test.err"
[[ ! -s "$tmpdir/test.out" ]]

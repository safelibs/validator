#!/usr/bin/env bash
# @testcase: usage-bzip2-r12-multi-file-test-all-pass
# @title: bzip2 -t with three valid bz2 files exits zero
# @description: Compresses three separate inputs into three .bz2 files and runs "bzip2 -t" on all three in one invocation, asserting exit zero and no stdout output.
# @timeout: 60
# @tags: usage, integrity, multi-file
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

for i in 1 2 3; do
    printf 'multi-file test payload %d\n' "$i" >"$tmpdir/in${i}.txt"
    bzip2 "$tmpdir/in${i}.txt"
    [[ -f "$tmpdir/in${i}.txt.bz2" ]]
done

bzip2 -t "$tmpdir/in1.txt.bz2" "$tmpdir/in2.txt.bz2" "$tmpdir/in3.txt.bz2" >"$tmpdir/out.txt"
[[ ! -s "$tmpdir/out.txt" ]]

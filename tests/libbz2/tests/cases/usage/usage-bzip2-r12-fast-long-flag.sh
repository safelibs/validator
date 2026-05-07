#!/usr/bin/env bash
# @testcase: usage-bzip2-r12-fast-long-flag
# @title: bzip2 --fast long alias produces same output as -1
# @description: Compresses identical content with --fast and with -1 to separate streams via -c and confirms the resulting bytes are identical, exercising the documented --fast=-1 long alias.
# @timeout: 60
# @tags: usage, compression, long-flag, fast
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

for i in $(seq 1 400); do
    printf 'fast-alias deterministic line %03d\n' "$i"
done >"$tmpdir/in.txt"

bzip2 --fast -c "$tmpdir/in.txt" >"$tmpdir/fast.bz2"
bzip2 -1 -c "$tmpdir/in.txt" >"$tmpdir/one.bz2"

cmp "$tmpdir/fast.bz2" "$tmpdir/one.bz2"

fast_sha=$(sha256sum "$tmpdir/fast.bz2" | awk '{print $1}')
one_sha=$(sha256sum "$tmpdir/one.bz2" | awk '{print $1}')
[[ "$fast_sha" == "$one_sha" ]]

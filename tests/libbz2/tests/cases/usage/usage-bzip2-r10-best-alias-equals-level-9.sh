#!/usr/bin/env bash
# @testcase: usage-bzip2-r10-best-alias-equals-level-9
# @title: bzip2 --best long alias produces the same output as -9
# @description: Compresses identical content with --best and with -9 to separate files and verifies the resulting .bz2 streams are byte-identical, confirming --best is exactly an alias for -9.
# @timeout: 60
# @tags: usage, compression, long-flag
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

for i in $(seq 1 500); do
    printf 'best-alias deterministic line %03d\n' "$i"
done >"$tmpdir/in.txt"

bzip2 --best -c "$tmpdir/in.txt" >"$tmpdir/best.bz2"
bzip2 -9 -c "$tmpdir/in.txt" >"$tmpdir/nine.bz2"

cmp "$tmpdir/best.bz2" "$tmpdir/nine.bz2"

best_sha=$(sha256sum "$tmpdir/best.bz2" | awk '{print $1}')
nine_sha=$(sha256sum "$tmpdir/nine.bz2" | awk '{print $1}')
[[ "$best_sha" == "$nine_sha" ]]

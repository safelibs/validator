#!/usr/bin/env bash
# @testcase: usage-bzip2-r11-combined-c-and-level
# @title: bzip2 -c1 combines stdout and level-1 in one short flag bundle
# @description: Compresses to stdout with the bundled short flags -c1 (write to stdout, level 1) and confirms the captured stream decompresses byte-for-byte while leaving the input file untouched (no .bz2 sibling created).
# @timeout: 60
# @tags: usage, compression, combined-flags, level
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

for i in $(seq 1 80); do
    printf 'combined-c1 payload line %02d\n' "$i"
done >"$tmpdir/in.txt"
orig_sha=$(sha256sum "$tmpdir/in.txt" | awk '{print $1}')

bzip2 -c1 "$tmpdir/in.txt" >"$tmpdir/out.bz2"

# Input untouched; -c does not produce a sibling .bz2.
[[ -f "$tmpdir/in.txt" ]]
[[ ! -e "$tmpdir/in.txt.bz2" ]]
after_sha=$(sha256sum "$tmpdir/in.txt" | awk '{print $1}')
[[ "$orig_sha" == "$after_sha" ]]

# Captured stream is decodable and equal to original.
bzip2 -dc "$tmpdir/out.bz2" >"$tmpdir/round.out"
round_sha=$(sha256sum "$tmpdir/round.out" | awk '{print $1}')
[[ "$orig_sha" == "$round_sha" ]]

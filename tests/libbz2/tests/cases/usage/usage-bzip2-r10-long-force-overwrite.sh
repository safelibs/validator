#!/usr/bin/env bash
# @testcase: usage-bzip2-r10-long-force-overwrite
# @title: bzip2 --force long flag overwrites an existing .bz2 target
# @description: Pre-creates a placeholder .bz2 file and then runs bzip2 --force, verifying the placeholder is replaced with a valid compressed stream of the source.
# @timeout: 60
# @tags: usage, compression, long-flag
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'long-force payload contents\n' >"$tmpdir/in.txt"
printf 'placeholder bytes that are not a real bz2 stream\n' >"$tmpdir/in.txt.bz2"

bzip2 --force "$tmpdir/in.txt"

[[ -f "$tmpdir/in.txt.bz2" ]]
[[ ! -f "$tmpdir/in.txt" ]]

# Decompress and verify the magic + content match the original.
head -c 3 "$tmpdir/in.txt.bz2" | od -An -c | tr -d ' \n' | grep -q 'BZh'
bzip2 -dc "$tmpdir/in.txt.bz2" >"$tmpdir/round"
grep -Fq 'long-force payload contents' "$tmpdir/round"

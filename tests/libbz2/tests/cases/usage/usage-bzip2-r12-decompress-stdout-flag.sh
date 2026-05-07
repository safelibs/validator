#!/usr/bin/env bash
# @testcase: usage-bzip2-r12-decompress-stdout-flag
# @title: bzip2 --decompress --stdout long-form decompresses to stdout without consuming input
# @description: Compresses a file with --keep, then decompresses it via "bzip2 --decompress --stdout" long-form flags and confirms the decoded bytes match the original while the source .bz2 file remains on disk untouched.
# @timeout: 60
# @tags: usage, decompression, long-flag, stdout
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

for i in $(seq 1 100); do
    printf 'r12-decompress-stdout payload %03d\n' "$i"
done >"$tmpdir/in.txt"
orig_sha=$(sha256sum "$tmpdir/in.txt" | awk '{print $1}')

bzip2 --keep "$tmpdir/in.txt"
[[ -f "$tmpdir/in.txt.bz2" ]]

before_sha=$(sha256sum "$tmpdir/in.txt.bz2" | awk '{print $1}')

bzip2 --decompress --stdout "$tmpdir/in.txt.bz2" >"$tmpdir/out.txt"

# .bz2 untouched.
[[ -f "$tmpdir/in.txt.bz2" ]]
after_sha=$(sha256sum "$tmpdir/in.txt.bz2" | awk '{print $1}')
[[ "$before_sha" == "$after_sha" ]]

# Decoded stdout matches the original payload.
out_sha=$(sha256sum "$tmpdir/out.txt" | awk '{print $1}')
[[ "$orig_sha" == "$out_sha" ]]

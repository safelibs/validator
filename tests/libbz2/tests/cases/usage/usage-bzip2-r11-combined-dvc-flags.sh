#!/usr/bin/env bash
# @testcase: usage-bzip2-r11-combined-dvc-flags
# @title: bzip2 -dvc combined decompress, verbose, and stdout short flags
# @description: Decompresses a .bz2 to stdout with the bundled short flags -dvc and confirms the original bytes are emitted on stdout while the verbose summary line is written on stderr; the input .bz2 must remain on disk because -c suppresses removal.
# @timeout: 60
# @tags: usage, decompression, combined-flags, verbose
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

for i in $(seq 1 80); do
    printf 'combined-dvc payload line %02d\n' "$i"
done >"$tmpdir/in.txt"
orig_sha=$(sha256sum "$tmpdir/in.txt" | awk '{print $1}')

bzip2 --keep "$tmpdir/in.txt"
[[ -f "$tmpdir/in.txt.bz2" ]]
rm "$tmpdir/in.txt"

bzip2 -dvc "$tmpdir/in.txt.bz2" >"$tmpdir/out.txt" 2>"$tmpdir/v.err"

# .bz2 remains because -c was passed.
[[ -f "$tmpdir/in.txt.bz2" ]]

out_sha=$(sha256sum "$tmpdir/out.txt" | awk '{print $1}')
[[ "$orig_sha" == "$out_sha" ]]

# Verbose stderr contains the input filename.
grep -F 'in.txt.bz2' "$tmpdir/v.err" >/dev/null

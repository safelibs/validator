#!/usr/bin/env bash
# @testcase: usage-bunzip2-r10-long-keep-flag
# @title: bunzip2 --keep long flag preserves the .bz2 input after decompression
# @description: Decompresses a .bz2 file with bunzip2 --keep and verifies both the original archive and the decompressed output exist with matching content.
# @timeout: 60
# @tags: usage, decompression, long-flag
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'bunzip2 long-keep payload\n' >"$tmpdir/in.txt"
bzip2 "$tmpdir/in.txt"

archive_sha=$(sha256sum "$tmpdir/in.txt.bz2" | awk '{print $1}')

bunzip2 --keep "$tmpdir/in.txt.bz2"

[[ -f "$tmpdir/in.txt" ]]
[[ -f "$tmpdir/in.txt.bz2" ]]

after_sha=$(sha256sum "$tmpdir/in.txt.bz2" | awk '{print $1}')
[[ "$archive_sha" == "$after_sha" ]]

grep -Fq 'bunzip2 long-keep payload' "$tmpdir/in.txt"

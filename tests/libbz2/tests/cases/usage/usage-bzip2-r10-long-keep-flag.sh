#!/usr/bin/env bash
# @testcase: usage-bzip2-r10-long-keep-flag
# @title: bzip2 --keep long flag preserves the source file
# @description: Compresses a file using the --keep long-form flag and verifies both the original and the .bz2 output remain on disk.
# @timeout: 60
# @tags: usage, compression, long-flag
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'long-keep payload\n%s\n' "$(seq 1 200)" >"$tmpdir/in.txt"
orig_sha=$(sha256sum "$tmpdir/in.txt" | awk '{print $1}')

bzip2 --keep "$tmpdir/in.txt"

[[ -f "$tmpdir/in.txt" ]]
[[ -f "$tmpdir/in.txt.bz2" ]]

after_sha=$(sha256sum "$tmpdir/in.txt" | awk '{print $1}')
[[ "$orig_sha" == "$after_sha" ]]

bzip2 -dc "$tmpdir/in.txt.bz2" >"$tmpdir/round"
cmp "$tmpdir/in.txt" "$tmpdir/round"

#!/usr/bin/env bash
# @testcase: usage-bzip2-r11-small-long-flag
# @title: bzip2 --small long-form roundtrips a file
# @description: Compresses a file with the --small long flag (memory-conservative decompressor mode flag) and verifies the .bz2 output decompresses back to the original payload byte-for-byte.
# @timeout: 60
# @tags: usage, compression, long-flag, small
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

for i in $(seq 1 80); do
    printf 'small-long-flag payload line %02d\n' "$i"
done >"$tmpdir/in.txt"
orig_sha=$(sha256sum "$tmpdir/in.txt" | awk '{print $1}')

bzip2 --small --keep "$tmpdir/in.txt"

[[ -f "$tmpdir/in.txt.bz2" ]]

bzip2 -dc "$tmpdir/in.txt.bz2" >"$tmpdir/round.txt"
round_sha=$(sha256sum "$tmpdir/round.txt" | awk '{print $1}')
[[ "$orig_sha" == "$round_sha" ]]

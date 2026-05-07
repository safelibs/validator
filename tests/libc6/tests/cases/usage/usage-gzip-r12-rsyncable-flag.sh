#!/usr/bin/env bash
# @testcase: usage-gzip-r12-rsyncable-flag
# @title: gzip --rsyncable produces a decompressible archive of identical content
# @description: Compresses a payload with gzip --rsyncable and verifies that gunzip -c restores the exact original bytes (rsyncable changes block boundaries but preserves content).
# @timeout: 60
# @tags: usage, gzip, rsyncable
# @client: gzip

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Build a payload large enough to exercise multiple deflate blocks.
LC_ALL=C awk 'BEGIN { for (i = 0; i < 4096; i++) printf "rsyncable line %d\n", i }' >"$tmpdir/plain.txt"

gzip --rsyncable -k "$tmpdir/plain.txt"
gunzip -c "$tmpdir/plain.txt.gz" >"$tmpdir/round.txt"
cmp "$tmpdir/plain.txt" "$tmpdir/round.txt"

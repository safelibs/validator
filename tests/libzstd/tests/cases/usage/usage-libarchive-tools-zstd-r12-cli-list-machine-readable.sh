#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r12-cli-list-machine-readable
# @title: zstd CLI -l --no-progress lists header info with the original byte count
# @description: Compresses a payload of known size, runs zstd -l on the resulting frame, and asserts the listing reports the canonical column header line and the exact decompressed byte count.
# @timeout: 60
# @tags: usage, zstd, cli, list
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 -c '
import sys
sys.stdout.buffer.write(b"r12 list payload row\n" * 1500)' >"$tmpdir/payload.bin"

original_bytes=$(stat -c %s "$tmpdir/payload.bin")
test "$original_bytes" -gt 0

zstd -q -o "$tmpdir/payload.zst" "$tmpdir/payload.bin"
validator_require_file "$tmpdir/payload.zst"

zstd -l "$tmpdir/payload.zst" >"$tmpdir/listing" 2>&1

# The standard -l listing must show the column header row.
validator_assert_contains "$tmpdir/listing" 'Frames'
validator_assert_contains "$tmpdir/listing" 'Compressed'
validator_assert_contains "$tmpdir/listing" 'Uncompressed'
validator_assert_contains "$tmpdir/listing" 'Ratio'
validator_assert_contains "$tmpdir/listing" 'payload.zst'

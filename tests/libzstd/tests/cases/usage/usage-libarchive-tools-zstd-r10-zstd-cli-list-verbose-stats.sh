#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r10-zstd-cli-list-verbose-stats
# @title: zstd CLI --list -v reports frame statistics
# @description: Compresses a sized payload, runs zstd --list -v on the resulting frame, and asserts the verbose listing exposes both the decompressed-size and ratio fields with the original byte count.
# @timeout: 120
# @tags: usage, archive, zstd, cli, list
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Generate a payload of a known, non-trivial size.
python3 -c '
import sys
chunk = b"list-verbose payload segment\n"
sys.stdout.buffer.write(chunk * 1024)
' >"$tmpdir/payload.bin"

original_bytes=$(stat -c %s "$tmpdir/payload.bin")
test "$original_bytes" -gt 0

zstd -q -o "$tmpdir/payload.zst" "$tmpdir/payload.bin"
validator_require_file "$tmpdir/payload.zst"

zstd --list -v "$tmpdir/payload.zst" >"$tmpdir/listing" 2>&1

# Verbose listing must expose the decompressed/original byte count and ratio.
validator_assert_contains "$tmpdir/listing" 'Decompressed Size:'
validator_assert_contains "$tmpdir/listing" 'Ratio:'
validator_assert_contains "$tmpdir/listing" "$original_bytes"

#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r15-cli-content-size-listing
# @title: zstd CLI default frame header records content size and -lv reports it
# @description: Compresses a payload with the default zstd CLI invocation (no --no-content-size), runs zstd -lv on the result, and asserts the verbose listing reports both the Decompressed Size and Ratio rows. Confirms the default frame header carries the content-size field that --no-content-size suppresses.
# @timeout: 60
# @tags: usage, archive, zstd, cli, listing
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/payload.bin"
python3 -c 'import sys
sys.stdout.buffer.write(b"r15 content-size default row\n" * 1500)' >"$src"
validator_require_file "$src"

zstd -q -o "$tmpdir/out.zst" "$src"
validator_require_file "$tmpdir/out.zst"

zstd -lv "$tmpdir/out.zst" >"$tmpdir/listing" 2>&1

validator_assert_contains "$tmpdir/listing" 'Compressed Size:'
validator_assert_contains "$tmpdir/listing" 'Decompressed Size:'
validator_assert_contains "$tmpdir/listing" 'Ratio:'

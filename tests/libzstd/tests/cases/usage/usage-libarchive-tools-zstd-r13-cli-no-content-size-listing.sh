#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r13-cli-no-content-size-listing
# @title: zstd CLI --no-content-size omits decompressed size from the frame header listing
# @description: Compresses a payload with zstd --no-content-size, runs zstd -lv on the result, and asserts the verbose listing omits the "Decompressed Size" line entirely (because the field was suppressed in the frame header) while the output still round-trips byte-for-byte.
# @timeout: 60
# @tags: usage, archive, zstd, cli, listing
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/payload.bin"
python3 -c 'import sys
sys.stdout.buffer.write(b"r13 no-content-size row\n" * 1500)' >"$src"
validator_require_file "$src"
src_sum=$(sha256sum "$src" | awk '{print $1}')

zstd -q --no-content-size -o "$tmpdir/out.zst" "$src"
validator_require_file "$tmpdir/out.zst"

zstd -lv "$tmpdir/out.zst" >"$tmpdir/listing" 2>&1

# A normal listing carries Compressed Size; with --no-content-size the
# "Decompressed Size:" / "Ratio:" rows are suppressed altogether.
grep -q 'Compressed Size:' "$tmpdir/listing"
if grep -q 'Decompressed Size:' "$tmpdir/listing"; then
    printf 'unexpected "Decompressed Size" with --no-content-size\n' >&2
    cat "$tmpdir/listing" >&2
    exit 1
fi

zstd -dq -c "$tmpdir/out.zst" >"$tmpdir/decoded.bin"
dst_sum=$(sha256sum "$tmpdir/decoded.bin" | awk '{print $1}')
test "$src_sum" = "$dst_sum"

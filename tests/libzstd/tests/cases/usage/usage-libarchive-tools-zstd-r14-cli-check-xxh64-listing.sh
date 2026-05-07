#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r14-cli-check-xxh64-listing
# @title: zstd --check writes an XXH64 content checksum that surfaces in zstd -lv listing
# @description: Compresses a payload with zstd --check, runs zstd -lv on the resulting frame, and asserts the verbose listing carries a "Check: XXH64" line confirming the per-frame content checksum was written. The frame must also pass -t integrity and round-trip byte-for-byte.
# @timeout: 60
# @tags: usage, archive, zstd, cli, checksum
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/payload.bin"
python3 -c 'import sys
sys.stdout.buffer.write(b"r14 --check XXH64 row\n" * 800)' >"$src"
src_sum=$(sha256sum "$src" | awk '{print $1}')

zstd -q --check -o "$tmpdir/out.zst" "$src"
validator_require_file "$tmpdir/out.zst"

zstd -lv "$tmpdir/out.zst" >"$tmpdir/listing" 2>&1
grep -q 'Check: XXH64' "$tmpdir/listing" || {
    printf 'expected "Check: XXH64" in listing under --check\n' >&2
    cat "$tmpdir/listing" >&2
    exit 1
}

zstd -tq "$tmpdir/out.zst"
zstd -dq -c "$tmpdir/out.zst" >"$tmpdir/decoded.bin"
dst_sum=$(sha256sum "$tmpdir/decoded.bin" | awk '{print $1}')
[[ "$src_sum" == "$dst_sum" ]]

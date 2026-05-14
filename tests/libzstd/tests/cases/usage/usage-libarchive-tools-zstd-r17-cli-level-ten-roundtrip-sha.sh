#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r17-cli-level-ten-roundtrip-sha
# @title: zstd -10 mid-level compression round-trips byte-for-byte via SHA-256
# @description: Compresses a generated payload with zstd -10, decompresses it back with zstd -d, and asserts the SHA-256 of the decoded bytes equals the source SHA-256, exercising a mid-range compression level path.
# @timeout: 60
# @tags: usage, archive, zstd, level
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/payload.bin"
python3 -c 'import sys
sys.stdout.buffer.write(b"r17 level10 payload row\n" * 800)' >"$src"
src_sum=$(sha256sum "$src" | awk '{print $1}')

zstd -q -10 -o "$tmpdir/out.zst" "$src"
zstd -dq -o "$tmpdir/decoded.bin" "$tmpdir/out.zst"
out_sum=$(sha256sum "$tmpdir/decoded.bin" | awk '{print $1}')
[[ "$out_sum" == "$src_sum" ]] || {
    printf 'sha mismatch src=%s out=%s\n' "$src_sum" "$out_sum" >&2
    exit 1
}

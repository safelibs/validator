#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r13-cli-keep-source-flag
# @title: zstd CLI -k preserves the source file alongside the produced .zst
# @description: Compresses a file with zstd -k and asserts both the original and the .zst exist afterwards, the source contents are unchanged, and the .zst decompresses back to the original SHA-256.
# @timeout: 60
# @tags: usage, archive, zstd, cli, keep
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/keep.bin"
python3 -c 'import sys
sys.stdout.buffer.write(b"r13 keep flag payload row\n" * 256)' >"$src"
validator_require_file "$src"
src_sum=$(sha256sum "$src" | awk '{print $1}')

(
  cd "$tmpdir"
  zstd -q -k keep.bin
)

# Both original and compressed must exist after -k.
validator_require_file "$tmpdir/keep.bin"
validator_require_file "$tmpdir/keep.bin.zst"

# Source contents are unchanged.
post_sum=$(sha256sum "$tmpdir/keep.bin" | awk '{print $1}')
test "$src_sum" = "$post_sum"

# Decompressed payload matches.
zstd -dq -c "$tmpdir/keep.bin.zst" >"$tmpdir/decoded.bin"
dst_sum=$(sha256sum "$tmpdir/decoded.bin" | awk '{print $1}')
test "$src_sum" = "$dst_sum"

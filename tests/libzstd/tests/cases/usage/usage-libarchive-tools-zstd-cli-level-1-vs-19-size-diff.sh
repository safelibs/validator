#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-cli-level-1-vs-19-size-diff
# @title: zstd CLI -1 vs -19 size differences on compressible payload
# @description: Compresses the same highly compressible payload with zstd -1 (fastest) and zstd -19 (high ratio), confirms both frames carry the zstd magic, both decompress back to the original byte stream, and the -19 output is no larger than the -1 output (and meaningfully smaller than the source).
# @timeout: 240
# @tags: usage, archive, zstd, cli
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Build a highly compressible payload deterministically without yes|head.
src="$tmpdir/payload.bin"
python3 -c 'import sys
sys.stdout.buffer.write(b"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" * 8192)' >"$src"
validator_require_file "$src"
src_size=$(stat -c %s "$src")

zstd -q -1 -o "$tmpdir/a.zst" "$src"
zstd -q -19 -o "$tmpdir/b.zst" "$src"
validator_require_file "$tmpdir/a.zst"
validator_require_file "$tmpdir/b.zst"

magic_a=$(od -An -N4 -tx1 "$tmpdir/a.zst" | tr -d ' \n')
magic_b=$(od -An -N4 -tx1 "$tmpdir/b.zst" | tr -d ' \n')
test "$magic_a" = "28b52ffd"
test "$magic_b" = "28b52ffd"

size_a=$(stat -c %s "$tmpdir/a.zst")
size_b=$(stat -c %s "$tmpdir/b.zst")
# Both compressed outputs must be meaningfully smaller than the source.
test "$size_a" -lt "$src_size"
test "$size_b" -lt "$src_size"
# Higher level should not be larger than lower level on this payload.
test "$size_b" -le "$size_a"

zstd -dq -c "$tmpdir/a.zst" >"$tmpdir/a.out"
zstd -dq -c "$tmpdir/b.zst" >"$tmpdir/b.out"
cmp "$src" "$tmpdir/a.out"
cmp "$src" "$tmpdir/b.out"

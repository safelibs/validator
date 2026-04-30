#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-cli-level-8-explicit
# @title: zstd CLI -8 explicit mid level compression
# @description: Compresses a repetitive payload with the standalone zstd CLI driving the encoder at level 8 (a mid-range tier between the documented -3 default and the long-mode -19 ceiling), verifies the resulting frame carries the zstd magic, passes -t integrity, decodes byte-for-byte to the original input, and produces strictly smaller output than the source.
# @timeout: 120
# @tags: usage, archive, zstd, cli
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/payload.bin"
python3 -c 'import sys
sys.stdout.buffer.write(b"level-8 mid-tier payload chunk\n" * 4096)' >"$src"
validator_require_file "$src"
src_sum=$(sha256sum "$src" | awk '{print $1}')

zstd -q -8 -o "$tmpdir/out.zst" "$src"
validator_require_file "$tmpdir/out.zst"

magic=$(od -An -N4 -tx1 "$tmpdir/out.zst" | tr -d ' \n')
test "$magic" = "28b52ffd"

zstd -tq "$tmpdir/out.zst"
zstd -dq -c "$tmpdir/out.zst" >"$tmpdir/decoded.bin"
cmp "$src" "$tmpdir/decoded.bin"

dst_sum=$(sha256sum "$tmpdir/decoded.bin" | awk '{print $1}')
test "$src_sum" = "$dst_sum"

# A repetitive payload at level 8 must compress strictly smaller than the source.
src_size=$(stat -c %s "$src")
zst_size=$(stat -c %s "$tmpdir/out.zst")
test "$zst_size" -lt "$src_size"

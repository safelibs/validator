#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-cli-format-lz4
# @title: zstd CLI --format=lz4 emits an lz4 frame
# @description: Compresses a payload with the zstd CLI using --format=lz4, asserts the resulting file carries the lz4 frame magic 04 22 4d 18 (not the zstd magic), and decompresses byte-for-byte back to the source through zstd -d so the lz4 codepath compiled into the CLI is validated end to end.
# @timeout: 120
# @tags: usage, archive, zstd, cli, format
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/payload.bin"
python3 -c 'import sys
sys.stdout.buffer.write(b"format-lz4 payload row\n" * 2048)' >"$src"
validator_require_file "$src"
src_sum=$(sha256sum "$src" | awk '{print $1}')

zstd -q --format=lz4 -o "$tmpdir/out.lz4" "$src"
validator_require_file "$tmpdir/out.lz4"

magic=$(od -An -N4 -tx1 "$tmpdir/out.lz4" | tr -d ' \n')
test "$magic" = "04224d18"

# zstd CLI decompresses lz4 streams via the same --format dispatch.
zstd -dq -c "$tmpdir/out.lz4" >"$tmpdir/decoded.bin"
dst_sum=$(sha256sum "$tmpdir/decoded.bin" | awk '{print $1}')
test "$src_sum" = "$dst_sum"

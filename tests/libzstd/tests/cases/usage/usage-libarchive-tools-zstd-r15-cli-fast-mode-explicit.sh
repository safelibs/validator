#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r15-cli-fast-mode-explicit
# @title: zstd --fast=5 produces a valid frame that decodes back to the original
# @description: Compresses a payload with zstd --fast=5 (negative compression level / fast mode 5), asserts the resulting file carries the standard zstd frame magic, passes -t integrity, and decompresses to a byte-identical SHA-256 of the source.
# @timeout: 60
# @tags: usage, archive, zstd, cli, fast
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/payload.bin"
python3 -c 'import sys
sys.stdout.buffer.write(b"r15 fast=5 payload row\n" * 4000)' >"$src"
src_sum=$(sha256sum "$src" | awk '{print $1}')

zstd -q --fast=5 -o "$tmpdir/out.zst" "$src"
validator_require_file "$tmpdir/out.zst"

magic=$(od -An -N4 -tx1 "$tmpdir/out.zst" | tr -d ' \n')
test "$magic" = "28b52ffd"

zstd -tq "$tmpdir/out.zst"

zstd -dq -c "$tmpdir/out.zst" >"$tmpdir/decoded.bin"
dst_sum=$(sha256sum "$tmpdir/decoded.bin" | awk '{print $1}')
test "$src_sum" = "$dst_sum"

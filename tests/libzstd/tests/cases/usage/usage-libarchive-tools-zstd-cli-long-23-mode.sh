#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-cli-long-23-mode
# @title: zstd CLI --long=23 expanded window
# @description: Compresses a payload with the standalone zstd CLI in long-range mode at window log 23 via --long=23, asserts the resulting frame carries the zstd magic, decodes with a matching --long=23 decoder budget, and round-trips byte-for-byte to the original input.
# @timeout: 180
# @tags: usage, archive, zstd, cli, long
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/payload.bin"
python3 -c 'import sys
sys.stdout.buffer.write(b"long-mode payload row 23 window\n" * 8192)' >"$src"
validator_require_file "$src"
src_sum=$(sha256sum "$src" | awk '{print $1}')

zstd -q --long=23 -o "$tmpdir/out.zst" "$src"
validator_require_file "$tmpdir/out.zst"

magic=$(od -An -N4 -tx1 "$tmpdir/out.zst" | tr -d ' \n')
test "$magic" = "28b52ffd"

zstd -tq "$tmpdir/out.zst"
zstd -dq --long=23 -c "$tmpdir/out.zst" >"$tmpdir/decoded.bin"
cmp "$src" "$tmpdir/decoded.bin"

dst_sum=$(sha256sum "$tmpdir/decoded.bin" | awk '{print $1}')
test "$src_sum" = "$dst_sum"

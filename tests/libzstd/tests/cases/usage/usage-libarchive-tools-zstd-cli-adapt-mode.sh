#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-cli-adapt-mode
# @title: zstd CLI --adapt adaptive compression level
# @description: Compresses a payload with --adapt so the zstd CLI dynamically tunes its compression level to I/O conditions, verifies the output frame carries the zstd magic, passes -t integrity, decodes byte-for-byte to the original input, and that the adaptive frame is strictly smaller than the source for repetitive data.
# @timeout: 180
# @tags: usage, archive, zstd, cli, adapt
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/payload.bin"
python3 -c 'import sys
sys.stdout.buffer.write(b"adaptive zstd payload segment\n" * 8192)' >"$src"
validator_require_file "$src"
src_sum=$(sha256sum "$src" | awk '{print $1}')

# --adapt requires streaming form: read from stdin, write to stdout.
zstd -q --adapt <"$src" >"$tmpdir/out.zst"
validator_require_file "$tmpdir/out.zst"

magic=$(od -An -N4 -tx1 "$tmpdir/out.zst" | tr -d ' \n')
test "$magic" = "28b52ffd"

zstd -tq "$tmpdir/out.zst"
zstd -dq -c "$tmpdir/out.zst" >"$tmpdir/decoded.bin"
cmp "$src" "$tmpdir/decoded.bin"

dst_sum=$(sha256sum "$tmpdir/decoded.bin" | awk '{print $1}')
test "$src_sum" = "$dst_sum"

src_size=$(stat -c %s "$src")
zst_size=$(stat -c %s "$tmpdir/out.zst")
test "$zst_size" -lt "$src_size"

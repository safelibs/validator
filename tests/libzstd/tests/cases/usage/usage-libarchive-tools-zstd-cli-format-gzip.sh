#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-cli-format-gzip
# @title: zstd CLI --format=gzip emits a gzip stream
# @description: Compresses a payload with the zstd CLI using --format=gzip, verifies the output carries the canonical 1f 8b gzip magic (not the zstd 28 b5 2f fd magic), decodes byte-for-byte through gunzip, and asserts the same payload survives a default zstd round-trip for comparison.
# @timeout: 120
# @tags: usage, archive, zstd, cli, format
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/payload.bin"
python3 -c 'import sys
sys.stdout.buffer.write(b"format-gzip payload row\n" * 2048)' >"$src"
validator_require_file "$src"
src_sum=$(sha256sum "$src" | awk '{print $1}')

zstd -q --format=gzip -o "$tmpdir/out.gz" "$src"
validator_require_file "$tmpdir/out.gz"

magic=$(od -An -N2 -tx1 "$tmpdir/out.gz" | tr -d ' \n')
test "$magic" = "1f8b"

# Decode through the system gunzip to confirm it is a real gzip stream.
gunzip -c "$tmpdir/out.gz" >"$tmpdir/decoded.bin"
dst_sum=$(sha256sum "$tmpdir/decoded.bin" | awk '{print $1}')
test "$src_sum" = "$dst_sum"

# Default format still produces a zstd frame.
zstd -q -o "$tmpdir/out.zst" "$src"
zmagic=$(od -An -N4 -tx1 "$tmpdir/out.zst" | tr -d ' \n')
test "$zmagic" = "28b52ffd"

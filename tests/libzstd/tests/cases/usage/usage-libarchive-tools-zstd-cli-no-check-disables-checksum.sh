#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-cli-no-check-disables-checksum
# @title: zstd CLI --no-check disables content checksum
# @description: Compresses the same payload twice with the zstd CLI, once with the default content checksum and once with --no-check, verifies the no-check variant is no larger than the default and that both decompress back to the original byte stream.
# @timeout: 120
# @tags: usage, archive, zstd, cli
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/payload.bin"
python3 -c 'import sys
sys.stdout.buffer.write(b"no-check payload\n" * 4096)' >"$src"
validator_require_file "$src"

zstd -q -o "$tmpdir/with.zst" "$src"
zstd -q --no-check -o "$tmpdir/without.zst" "$src"
validator_require_file "$tmpdir/with.zst"
validator_require_file "$tmpdir/without.zst"

magic_w=$(od -An -N4 -tx1 "$tmpdir/with.zst" | tr -d ' \n')
magic_n=$(od -An -N4 -tx1 "$tmpdir/without.zst" | tr -d ' \n')
test "$magic_w" = "28b52ffd"
test "$magic_n" = "28b52ffd"

size_w=$(stat -c %s "$tmpdir/with.zst")
size_n=$(stat -c %s "$tmpdir/without.zst")
# --no-check strips the trailing 4-byte XXH64 checksum; size must not grow.
test "$size_n" -le "$size_w"

zstd -tq "$tmpdir/with.zst"
zstd -tq "$tmpdir/without.zst"

zstd -dq -c "$tmpdir/with.zst" >"$tmpdir/with.out"
zstd -dq -c "$tmpdir/without.zst" >"$tmpdir/without.out"
cmp "$src" "$tmpdir/with.out"
cmp "$src" "$tmpdir/without.out"

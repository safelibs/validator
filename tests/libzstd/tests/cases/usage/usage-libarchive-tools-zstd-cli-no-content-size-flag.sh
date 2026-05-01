#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-cli-no-content-size-flag
# @title: zstd CLI --no-content-size omits decompressed size
# @description: Compresses the same payload twice with the zstd CLI - once with the default frame header and once with --no-content-size - asserts both round-trip cleanly via -d and -t and that the no-content-size variant is no larger than the default since the frame content size field is omitted.
# @timeout: 120
# @tags: usage, archive, zstd, cli
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/payload.bin"
python3 -c 'import sys
sys.stdout.buffer.write(b"no-content-size payload\n" * 4096)' >"$src"
validator_require_file "$src"

zstd -q -o "$tmpdir/with.zst" "$src"
zstd -q --no-content-size <"$src" >"$tmpdir/without.zst"
validator_require_file "$tmpdir/with.zst"
validator_require_file "$tmpdir/without.zst"

magic_w=$(od -An -N4 -tx1 "$tmpdir/with.zst" | tr -d ' \n')
magic_n=$(od -An -N4 -tx1 "$tmpdir/without.zst" | tr -d ' \n')
test "$magic_w" = "28b52ffd"
test "$magic_n" = "28b52ffd"

size_w=$(stat -c %s "$tmpdir/with.zst")
size_n=$(stat -c %s "$tmpdir/without.zst")
test "$size_n" -le "$size_w"

zstd -tq "$tmpdir/with.zst"
zstd -tq "$tmpdir/without.zst"

zstd -dq -c "$tmpdir/with.zst" >"$tmpdir/with.out"
zstd -dq -c "$tmpdir/without.zst" >"$tmpdir/without.out"
cmp "$src" "$tmpdir/with.out"
cmp "$src" "$tmpdir/without.out"

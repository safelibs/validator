#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-cli-decompress-output-flag
# @title: zstd CLI -d -o explicit decompress output path
# @description: Compresses a payload, removes the source, and decompresses with zstd -d -o pointing at an arbitrary destination path that does not match the .zst stem, asserts the destination is created, has the original byte-for-byte content, and that the compressed input is preserved by the default --keep behavior.
# @timeout: 120
# @tags: usage, archive, zstd, cli, decompress
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/original.bin"
python3 -c 'import sys
sys.stdout.buffer.write(b"decompress -o output payload\n" * 2048)' >"$src"
validator_require_file "$src"
src_sum=$(sha256sum "$src" | awk '{print $1}')

zstd -q -o "$tmpdir/archive.zst" "$src"
validator_require_file "$tmpdir/archive.zst"

# Decompress to a name that has no relation to the .zst stem.
zstd -dq -o "$tmpdir/restored.dat" "$tmpdir/archive.zst"
validator_require_file "$tmpdir/restored.dat"

dst_sum=$(sha256sum "$tmpdir/restored.dat" | awk '{print $1}')
test "$src_sum" = "$dst_sum"

# Default keep behavior must leave the .zst input in place.
validator_require_file "$tmpdir/archive.zst"

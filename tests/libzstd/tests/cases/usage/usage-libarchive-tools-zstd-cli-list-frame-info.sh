#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-cli-list-frame-info
# @title: zstd CLI --list reports frame metadata
# @description: Compresses a known payload with the zstd CLI then runs zstd --list on the output, asserts the listing is non-empty and references the input filename so the frame metadata reader is exercised end-to-end.
# @timeout: 120
# @tags: usage, archive, zstd, cli, list
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/payload.bin"
python3 -c 'import sys
sys.stdout.buffer.write(b"list-frame payload row\n" * 4096)' >"$src"
validator_require_file "$src"

zstd -q -o "$tmpdir/out.zst" "$src"
validator_require_file "$tmpdir/out.zst"

listing="$tmpdir/listing.txt"
zstd --list "$tmpdir/out.zst" >"$listing"
validator_require_file "$listing"
test -s "$listing"
grep -q 'out.zst' "$listing"

zstd -tq "$tmpdir/out.zst"
zstd -dq -c "$tmpdir/out.zst" >"$tmpdir/decoded.bin"
cmp "$src" "$tmpdir/decoded.bin"

#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r17-cli-check-xxhash-trailer-present
# @title: zstd --check compressed frame validates cleanly under zstd -t
# @description: Compresses a payload with the explicit --check option (enabling the XXH64 content checksum) and asserts the produced .zst frame passes 'zstd -t' integrity verification.
# @timeout: 60
# @tags: usage, archive, zstd, checksum
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/payload.bin"
python3 -c 'import sys
sys.stdout.buffer.write(b"r17 check payload row\n" * 400)' >"$src"

zstd -q --check -o "$tmpdir/out.zst" "$src"
validator_require_file "$tmpdir/out.zst"

zstd -t "$tmpdir/out.zst" >"$tmpdir/stdout.bin" 2>"$tmpdir/stderr.log"
test ! -s "$tmpdir/stdout.bin"

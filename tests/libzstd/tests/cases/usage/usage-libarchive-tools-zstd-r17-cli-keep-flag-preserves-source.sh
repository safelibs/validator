#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r17-cli-keep-flag-preserves-source
# @title: zstd --keep retains the source file after a successful compression
# @description: Compresses a small payload with zstd --keep and asserts the source file still exists after the run (default behavior on modern zstd, but the --keep flag pins it explicitly), and that the produced .zst file is non-empty.
# @timeout: 60
# @tags: usage, archive, zstd, cli, keep
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/payload.bin"
python3 -c 'import sys
sys.stdout.buffer.write(b"r17 keep payload row\n" * 500)' >"$src"

zstd -q --keep "$src" -o "$tmpdir/out.zst"
validator_require_file "$src"
validator_require_file "$tmpdir/out.zst"
test -s "$tmpdir/out.zst"

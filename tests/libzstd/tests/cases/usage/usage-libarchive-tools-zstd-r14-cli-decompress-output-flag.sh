#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r14-cli-decompress-output-flag
# @title: zstd -d -o <file> writes the decoded payload to the named output file
# @description: Compresses a payload, runs zstd -d -o <out> against the .zst archive, and asserts the decoded output file exists at the named path, matches the source byte-for-byte by SHA-256, and that the original .zst input is preserved on disk.
# @timeout: 60
# @tags: usage, archive, zstd, cli, decompress
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/payload.bin"
python3 -c 'import sys
sys.stdout.buffer.write(b"r14 d -o output flag row\n" * 1024)' >"$src"
validator_require_file "$src"
src_sum=$(sha256sum "$src" | awk '{print $1}')

zstd -q -o "$tmpdir/payload.zst" "$src"
validator_require_file "$tmpdir/payload.zst"

# Decompress with an explicit output filename via -o.
zstd -dq -o "$tmpdir/decoded.bin" "$tmpdir/payload.zst"
validator_require_file "$tmpdir/decoded.bin"

# Source archive preserved (no implicit --rm).
validator_require_file "$tmpdir/payload.zst"

dst_sum=$(sha256sum "$tmpdir/decoded.bin" | awk '{print $1}')
[[ "$src_sum" == "$dst_sum" ]] || {
    printf 'sha256 mismatch after -d -o roundtrip\n' >&2
    exit 1
}

#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r13-cli-stdin-c-pipeline
# @title: zstd -c reads stdin and writes a frame to stdout for shell pipelines
# @description: Pipes a payload into zstd -c (stdout streaming), captures the produced bytes, asserts the captured stream begins with the zstd frame magic 0x28b52ffd and round-trips back to the original SHA-256 via zstd -dq -c.
# @timeout: 60
# @tags: usage, archive, zstd, cli, stdin
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/payload.bin"
python3 -c 'import sys
sys.stdout.buffer.write(b"r13 stdin pipeline payload row\n" * 1024)' >"$src"
src_sum=$(sha256sum "$src" | awk '{print $1}')

# zstd -c on stdin emits a complete .zst frame on stdout.
zstd -q -c <"$src" >"$tmpdir/out.zst"
validator_require_file "$tmpdir/out.zst"

magic=$(od -An -N4 -tx1 "$tmpdir/out.zst" | tr -d ' \n')
test "$magic" = "28b52ffd"

# Round-trip via stdin/stdout decompression.
zstd -dq -c <"$tmpdir/out.zst" >"$tmpdir/decoded.bin"
dst_sum=$(sha256sum "$tmpdir/decoded.bin" | awk '{print $1}')
test "$src_sum" = "$dst_sum"

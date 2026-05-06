#!/usr/bin/env bash
# @testcase: usage-bzip2-batch12-decompress-binary-256-bytes
# @title: bzip2 roundtrip preserves all 256 byte values
# @description: Compresses a 256-byte payload containing all byte values 0x00..0xff with bzip2 and verifies decompression returns the exact same bytes.
# @timeout: 60
# @tags: usage, compression, binary
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 -c 'import sys; sys.stdout.buffer.write(bytes(range(256)))' >"$tmpdir/in.bin"
[[ "$(stat -c '%s' "$tmpdir/in.bin")" == 256 ]]

bzip2 -c "$tmpdir/in.bin" >"$tmpdir/in.bin.bz2"
bzip2 -dc "$tmpdir/in.bin.bz2" >"$tmpdir/out.bin"

cmp "$tmpdir/in.bin" "$tmpdir/out.bin"
[[ "$(stat -c '%s' "$tmpdir/out.bin")" == 256 ]]

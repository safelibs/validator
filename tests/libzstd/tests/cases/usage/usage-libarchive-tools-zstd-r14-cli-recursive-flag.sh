#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r14-cli-recursive-flag
# @title: zstd -r recursively compresses every regular file under a directory
# @description: Populates a directory with multiple regular files, runs zstd -r against the directory, and asserts each input file gains a sibling .zst archive that passes -t integrity and decompresses byte-for-byte to the corresponding source. The flag must accept a directory argument and walk it recursively.
# @timeout: 120
# @tags: usage, archive, zstd, cli, recursive
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

tree="$tmpdir/tree"
mkdir -p "$tree/sub"
python3 -c 'import sys
sys.stdout.buffer.write(b"r14 recursive a row\n" * 200)' >"$tree/a.bin"
python3 -c 'import sys
sys.stdout.buffer.write(b"r14 recursive b row\n" * 200)' >"$tree/sub/b.bin"

a_sum=$(sha256sum "$tree/a.bin" | awk '{print $1}')
b_sum=$(sha256sum "$tree/sub/b.bin" | awk '{print $1}')

zstd -q -r "$tree"

validator_require_file "$tree/a.bin.zst"
validator_require_file "$tree/sub/b.bin.zst"

zstd -tq "$tree/a.bin.zst"
zstd -tq "$tree/sub/b.bin.zst"

zstd -dq -c "$tree/a.bin.zst" >"$tmpdir/a.out"
zstd -dq -c "$tree/sub/b.bin.zst" >"$tmpdir/b.out"

[[ "$a_sum" == "$(sha256sum "$tmpdir/a.out" | awk '{print $1}')" ]]
[[ "$b_sum" == "$(sha256sum "$tmpdir/b.out" | awk '{print $1}')" ]]

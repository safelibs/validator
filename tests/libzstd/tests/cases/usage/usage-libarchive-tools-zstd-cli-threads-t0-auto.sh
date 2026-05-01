#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-cli-threads-t0-auto
# @title: zstd CLI -T0 auto-detect worker count
# @description: Compresses a payload with the standalone zstd CLI invoked as -T0 so the encoder selects the worker count from the available CPU topology, asserts the resulting frame carries the zstd magic, passes -t integrity, and decodes byte-for-byte to the original input.
# @timeout: 180
# @tags: usage, archive, zstd, cli, threads
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/payload.bin"
python3 -c 'import sys
sys.stdout.buffer.write(b"threads-auto payload row\n" * 8192)' >"$src"
validator_require_file "$src"
src_sum=$(sha256sum "$src" | awk '{print $1}')

zstd -q -T0 -o "$tmpdir/out.zst" "$src"
validator_require_file "$tmpdir/out.zst"

magic=$(od -An -N4 -tx1 "$tmpdir/out.zst" | tr -d ' \n')
test "$magic" = "28b52ffd"

zstd -tq "$tmpdir/out.zst"
zstd -dq -c "$tmpdir/out.zst" >"$tmpdir/decoded.bin"
cmp "$src" "$tmpdir/decoded.bin"

dst_sum=$(sha256sum "$tmpdir/decoded.bin" | awk '{print $1}')
test "$src_sum" = "$dst_sum"

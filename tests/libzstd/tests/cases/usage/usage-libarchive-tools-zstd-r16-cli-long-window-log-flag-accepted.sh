#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r16-cli-long-window-log-flag-accepted
# @title: zstd --long=24 accepts an explicit window-log and decompresses with --long to the same source
# @description: Compresses a payload with zstd --long=24, asserts the file exists with the standard zstd frame magic, then decompresses with zstd -d --long=24 and verifies the SHA-256 round-trip equals the source — exercising the long-mode window-log flag path on both encode and decode.
# @timeout: 120
# @tags: usage, archive, zstd, cli, long
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/payload.bin"
python3 -c 'import sys
sys.stdout.buffer.write(b"r16 long-window-log payload row\n" * 4000)' >"$src"
src_sum=$(sha256sum "$src" | awk '{print $1}')

zstd -q --long=24 -o "$tmpdir/out.zst" "$src"
validator_require_file "$tmpdir/out.zst"

magic=$(od -An -N4 -tx1 "$tmpdir/out.zst" | tr -d ' \n')
test "$magic" = "28b52ffd"

zstd -dq --long=24 -c "$tmpdir/out.zst" >"$tmpdir/decoded.bin"
test "$(sha256sum "$tmpdir/decoded.bin" | awk '{print $1}')" = "$src_sum"

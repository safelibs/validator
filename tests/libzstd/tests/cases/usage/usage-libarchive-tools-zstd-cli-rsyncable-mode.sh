#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-cli-rsyncable-mode
# @title: zstd CLI --rsyncable mode round-trip
# @description: Compresses a payload with --rsyncable so the encoder emits a stream tuned for rsync-friendly chunk boundaries, verifies the resulting frame carries the zstd magic, passes -t integrity, and decodes byte-for-byte to the original source.
# @timeout: 180
# @tags: usage, archive, zstd, cli, rsyncable
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/payload.bin"
python3 -c 'import sys
sys.stdout.buffer.write(b"rsyncable zstd payload chunk row\n" * 8192)' >"$src"
validator_require_file "$src"
src_sum=$(sha256sum "$src" | awk '{print $1}')

# --rsyncable is a streaming-mode option: feed via stdin/stdout.
zstd -q --rsyncable <"$src" >"$tmpdir/out.zst"
validator_require_file "$tmpdir/out.zst"

magic=$(od -An -N4 -tx1 "$tmpdir/out.zst" | tr -d ' \n')
test "$magic" = "28b52ffd"

zstd -tq "$tmpdir/out.zst"
zstd -dq -c "$tmpdir/out.zst" >"$tmpdir/decoded.bin"
cmp "$src" "$tmpdir/decoded.bin"

dst_sum=$(sha256sum "$tmpdir/decoded.bin" | awk '{print $1}')
test "$src_sum" = "$dst_sum"

src_size=$(stat -c %s "$src")
zst_size=$(stat -c %s "$tmpdir/out.zst")
test "$zst_size" -lt "$src_size"

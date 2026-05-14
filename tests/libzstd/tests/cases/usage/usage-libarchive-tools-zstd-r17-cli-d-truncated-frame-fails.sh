#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r17-cli-d-truncated-frame-fails
# @title: zstd -d on a truncated frame exits non-zero and refuses to emit a clean decode
# @description: Compresses a payload, truncates the resulting .zst file to a fraction of its size, runs zstd -d on the truncated frame, and asserts the decoder exits non-zero, exercising the corrupted/truncated frame rejection path.
# @timeout: 60
# @tags: usage, archive, zstd, truncated, negative
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/payload.bin"
python3 -c 'import sys
sys.stdout.buffer.write(b"r17 truncated payload row\n" * 600)' >"$src"
zstd -q -o "$tmpdir/out.zst" "$src"
full=$(wc -c <"$tmpdir/out.zst")
[[ "$full" -gt 32 ]]

# Truncate to half size — must yield an unrecoverable frame.
half=$(( full / 2 ))
dd if="$tmpdir/out.zst" of="$tmpdir/trunc.zst" bs=1 count="$half" status=none

if zstd -dq -o "$tmpdir/decoded.bin" "$tmpdir/trunc.zst" 2>"$tmpdir/err.log"; then
    echo "expected zstd -d to fail on truncated frame" >&2
    exit 1
fi

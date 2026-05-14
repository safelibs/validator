#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r17-cli-m-flag-memory-limit-accepted
# @title: zstd -d -M128 decompress accepts an explicit memory-usage limit and decodes a small frame
# @description: Compresses a small payload, then runs 'zstd -d -M128' (memory-usage limit 128 megabytes) on the resulting .zst file and asserts the decoded output matches the source SHA-256, exercising the -M flag on a frame that fits well within the limit.
# @timeout: 60
# @tags: usage, archive, zstd, memory-limit
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/payload.bin"
python3 -c 'import sys
sys.stdout.buffer.write(b"r17 memlimit payload row\n" * 1000)' >"$src"
src_sum=$(sha256sum "$src" | awk '{print $1}')

zstd -q -o "$tmpdir/out.zst" "$src"
zstd -dq -M128 -o "$tmpdir/decoded.bin" "$tmpdir/out.zst"
out_sum=$(sha256sum "$tmpdir/decoded.bin" | awk '{print $1}')
[[ "$out_sum" == "$src_sum" ]] || {
    printf 'sha mismatch src=%s out=%s\n' "$src_sum" "$out_sum" >&2
    exit 1
}

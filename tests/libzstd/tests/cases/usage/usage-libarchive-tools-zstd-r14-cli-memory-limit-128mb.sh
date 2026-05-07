#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r14-cli-memory-limit-128mb
# @title: zstd --memory=128MB raises the decoder memory ceiling and decodes the frame
# @description: Compresses a payload, decompresses it with zstd --memory=128MB to set an explicit decoder memory ceiling well above the frame requirement, and asserts the decoded output matches the source byte-for-byte. The flag must be accepted and the transfer must complete cleanly.
# @timeout: 60
# @tags: usage, archive, zstd, cli, memory
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/payload.bin"
python3 -c 'import sys
sys.stdout.buffer.write(b"r14 memory=128MB payload row\n" * 4000)' >"$src"
src_sum=$(sha256sum "$src" | awk '{print $1}')

zstd -q -o "$tmpdir/out.zst" "$src"
validator_require_file "$tmpdir/out.zst"

zstd -q --memory=128MB -d -o "$tmpdir/decoded.bin" "$tmpdir/out.zst"
validator_require_file "$tmpdir/decoded.bin"

dst_sum=$(sha256sum "$tmpdir/decoded.bin" | awk '{print $1}')
[[ "$src_sum" == "$dst_sum" ]] || {
    printf 'sha256 mismatch after --memory=128MB decode\n' >&2
    exit 1
}

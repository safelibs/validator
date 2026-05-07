#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r14-cli-decompress-long-flag
# @title: zstd --decompress long flag is accepted as a synonym for -d
# @description: Compresses a payload, decompresses the resulting frame using the long flag form --decompress (instead of the short -d), and asserts the decoded output matches the source SHA-256 and the .zst input file is preserved on disk.
# @timeout: 60
# @tags: usage, archive, zstd, cli, decompress
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/payload.bin"
python3 -c 'import sys
sys.stdout.buffer.write(b"r14 --decompress flag row\n" * 800)' >"$src"
src_sum=$(sha256sum "$src" | awk '{print $1}')

zstd -q -o "$tmpdir/out.zst" "$src"
validator_require_file "$tmpdir/out.zst"

zstd -q --decompress -o "$tmpdir/decoded.bin" "$tmpdir/out.zst"
validator_require_file "$tmpdir/decoded.bin"
validator_require_file "$tmpdir/out.zst"

dst_sum=$(sha256sum "$tmpdir/decoded.bin" | awk '{print $1}')
[[ "$src_sum" == "$dst_sum" ]] || {
    printf 'sha256 mismatch after --decompress roundtrip\n' >&2
    exit 1
}

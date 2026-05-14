#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r17-cli-stdin-pipe-roundtrip-sha
# @title: zstd compress-from-stdin then decompress-to-stdout round-trips byte-for-byte via SHA
# @description: Pipes a generated payload into 'zstd' (compress, stdin->stdout) and then through 'zstd -d' (decompress, stdin->stdout), and asserts the SHA-256 of the decompressed bytes equals the source SHA-256.
# @timeout: 60
# @tags: usage, archive, zstd, stdin, sha
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/payload.bin"
python3 -c 'import sys
sys.stdout.buffer.write(b"r17 stdin-pipe payload row\n" * 700)' >"$src"
src_sum=$(sha256sum "$src" | awk '{print $1}')

cat "$src" | zstd -q | zstd -dq >"$tmpdir/out.bin"
out_sum=$(sha256sum "$tmpdir/out.bin" | awk '{print $1}')
[[ "$out_sum" == "$src_sum" ]] || {
    printf 'sha mismatch src=%s out=%s\n' "$src_sum" "$out_sum" >&2
    exit 1
}

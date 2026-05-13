#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r16-cli-rm-removes-source-after-compress
# @title: zstd --rm removes the original input file after a successful compression
# @description: Creates an input file, compresses it with zstd --rm to a sibling .zst output, asserts the original input file no longer exists while the .zst output is present and decompresses to a byte-identical SHA-256 of the captured-before-deletion source bytes.
# @timeout: 60
# @tags: usage, archive, zstd, cli, rm
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/payload.bin"
python3 -c 'import sys
sys.stdout.buffer.write(b"r16 rm-removes-source payload row\n" * 500)' >"$src"
src_sum=$(sha256sum "$src" | awk '{print $1}')

zstd -q --rm "$src"

[[ ! -e "$src" ]] || {
    printf 'expected source to be removed by --rm, still present\n' >&2
    exit 1
}
validator_require_file "$tmpdir/payload.bin.zst"

zstd -dq -c "$tmpdir/payload.bin.zst" >"$tmpdir/decoded.bin"
test "$(sha256sum "$tmpdir/decoded.bin" | awk '{print $1}')" = "$src_sum"

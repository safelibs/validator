#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r13-cli-output-rename
# @title: zstd CLI -o renames the output file independently of the input stem
# @description: Compresses input.bin with zstd -o renamed.zstdata to a non-default extension, asserts the chosen output path is created with valid zstd magic, the input is preserved, and the renamed archive round-trips byte-for-byte.
# @timeout: 60
# @tags: usage, archive, zstd, cli, output
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/input.bin"
python3 -c 'import sys
sys.stdout.buffer.write(b"r13 output rename payload row\n" * 512)' >"$src"
validator_require_file "$src"
src_sum=$(sha256sum "$src" | awk '{print $1}')

zstd -q -o "$tmpdir/renamed.zstdata" "$src"
validator_require_file "$tmpdir/renamed.zstdata"
validator_require_file "$src"

magic=$(od -An -N4 -tx1 "$tmpdir/renamed.zstdata" | tr -d ' \n')
test "$magic" = "28b52ffd"

zstd -dq -c "$tmpdir/renamed.zstdata" >"$tmpdir/decoded.bin"
dst_sum=$(sha256sum "$tmpdir/decoded.bin" | awk '{print $1}')
test "$src_sum" = "$dst_sum"

# Default-named .zst file must NOT exist - -o should redirect entirely.
[[ ! -e "$tmpdir/input.bin.zst" ]] || {
    printf 'unexpected default %s alongside -o output\n' "$tmpdir/input.bin.zst" >&2
    exit 1
}

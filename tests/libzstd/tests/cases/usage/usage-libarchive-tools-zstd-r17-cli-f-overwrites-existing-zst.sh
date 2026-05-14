#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r17-cli-f-overwrites-existing-zst
# @title: zstd -f overwrites a pre-existing .zst output file without prompting
# @description: Creates a stub .zst output, runs zstd -f on a fresh source pointing at the same output path, and asserts the resulting file is a valid zstd frame (begins with the 0x28b52ffd magic) and decompresses back to the source payload.
# @timeout: 60
# @tags: usage, archive, zstd, force
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/payload.bin"
python3 -c 'import sys
sys.stdout.buffer.write(b"r17 overwrite payload row\n" * 400)' >"$src"
src_sum=$(sha256sum "$src" | awk '{print $1}')

printf 'stub-content' >"$tmpdir/out.zst"
zstd -q -f -o "$tmpdir/out.zst" "$src"

magic=$(od -An -N4 -tx1 "$tmpdir/out.zst" | tr -d ' \n')
[[ "$magic" == "28b52ffd" ]] || {
    printf 'expected zstd frame magic 28b52ffd, got %s\n' "$magic" >&2
    exit 1
}

zstd -dq -o "$tmpdir/decoded.bin" "$tmpdir/out.zst"
out_sum=$(sha256sum "$tmpdir/decoded.bin" | awk '{print $1}')
[[ "$out_sum" == "$src_sum" ]]

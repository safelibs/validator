#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r16-cli-level-1-vs-19-size-monotonic
# @title: zstd -19 produces a strictly smaller payload than zstd -1 on a repetitive source
# @description: Compresses a highly repetitive payload with zstd -1 and zstd -19, asserts both files decompress back to the byte-identical source via SHA-256, and confirms the -19 output is strictly smaller than the -1 output — exercising the level knob's monotonic size response on compressible input.
# @timeout: 120
# @tags: usage, archive, zstd, cli, level
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/payload.bin"
python3 -c 'import sys
sys.stdout.buffer.write(b"r16 repetitive zstd payload row alpha bravo charlie\n" * 4000)' >"$src"
src_sum=$(sha256sum "$src" | awk '{print $1}')

zstd -q -1 -o "$tmpdir/l1.zst" "$src"
zstd -q -19 -o "$tmpdir/l19.zst" "$src"

s1=$(wc -c <"$tmpdir/l1.zst")
s19=$(wc -c <"$tmpdir/l19.zst")
[[ "$s19" -lt "$s1" ]] || {
    printf 'expected -19 (%s) < -1 (%s)\n' "$s19" "$s1" >&2
    exit 1
}

zstd -dq -c "$tmpdir/l1.zst" >"$tmpdir/l1.bin"
zstd -dq -c "$tmpdir/l19.zst" >"$tmpdir/l19.bin"
test "$(sha256sum "$tmpdir/l1.bin" | awk '{print $1}')" = "$src_sum"
test "$(sha256sum "$tmpdir/l19.bin" | awk '{print $1}')" = "$src_sum"

#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-cli-check-xxhash-trailer
# @title: zstd CLI --check appends xxhash trailer
# @description: Compresses the same payload twice with the zstd CLI, once with --no-check and once with --check, asserts the --check output is at least four bytes longer to account for the trailing XXH64 content checksum and that both variants pass -t and decode byte-for-byte to the original input.
# @timeout: 120
# @tags: usage, archive, zstd, cli, checksum
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/payload.bin"
python3 -c 'import sys
sys.stdout.buffer.write(b"xxhash trailer payload row\n" * 4096)' >"$src"
validator_require_file "$src"
src_sum=$(sha256sum "$src" | awk '{print $1}')

zstd -q --no-check -o "$tmpdir/plain.zst" "$src"
zstd -q --check -o "$tmpdir/checked.zst" "$src"
validator_require_file "$tmpdir/plain.zst"
validator_require_file "$tmpdir/checked.zst"

size_p=$(stat -c %s "$tmpdir/plain.zst")
size_c=$(stat -c %s "$tmpdir/checked.zst")
diff=$(( size_c - size_p ))
test "$diff" -ge 4

zstd -tq "$tmpdir/plain.zst"
zstd -tq "$tmpdir/checked.zst"

zstd -dq -c "$tmpdir/plain.zst" >"$tmpdir/plain.out"
zstd -dq -c "$tmpdir/checked.zst" >"$tmpdir/checked.out"
cmp "$src" "$tmpdir/plain.out"
cmp "$src" "$tmpdir/checked.out"

p_sum=$(sha256sum "$tmpdir/plain.out" | awk '{print $1}')
c_sum=$(sha256sum "$tmpdir/checked.out" | awk '{print $1}')
test "$src_sum" = "$p_sum"
test "$src_sum" = "$c_sum"

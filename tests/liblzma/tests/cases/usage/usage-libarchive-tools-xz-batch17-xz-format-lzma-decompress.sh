#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-batch17-xz-format-lzma-decompress
# @title: xz -F lzma decompress legacy stream
# @description: Compresses a tar with xz -F lzma, then decompresses with xz -F lzma -d -c on the legacy .lzma stream and confirms bsdtar reads members through liblzma.
# @timeout: 180
# @tags: usage, archive, xz, cli, lzma
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/src" "$tmpdir/out"
printf 'legacy lzma reader payload\n' >"$tmpdir/src/alpha.txt"
printf 'legacy lzma reader payload two\n' >"$tmpdir/src/beta.txt"
src_sha_alpha=$(sha256sum "$tmpdir/src/alpha.txt" | awk '{print $1}')

bsdtar -cf "$tmpdir/plain.tar" -C "$tmpdir/src" alpha.txt beta.txt
xz -F lzma -z -c "$tmpdir/plain.tar" >"$tmpdir/plain.tar.lzma"

# Legacy .lzma magic 5d 00 00
magic_hex=$(head -c 3 "$tmpdir/plain.tar.lzma" | od -An -tx1 | tr -d ' \n')
test "$magic_hex" = "5d0000"

# Decompress with -F lzma -d -c (explicit format on the read side) and feed bsdtar.
xz -F lzma -d -c "$tmpdir/plain.tar.lzma" >"$tmpdir/plain.tar.dec"
bsdtar -tf "$tmpdir/plain.tar.dec" >"$tmpdir/list.txt"
validator_assert_contains "$tmpdir/list.txt" 'alpha.txt'
validator_assert_contains "$tmpdir/list.txt" 'beta.txt'

bsdtar -xf "$tmpdir/plain.tar.dec" -C "$tmpdir/out"
out_sha_alpha=$(sha256sum "$tmpdir/out/alpha.txt" | awk '{print $1}')
[[ "$src_sha_alpha" == "$out_sha_alpha" ]] || {
  printf 'sha mismatch: %s vs %s\n' "$src_sha_alpha" "$out_sha_alpha" >&2
  exit 1
}

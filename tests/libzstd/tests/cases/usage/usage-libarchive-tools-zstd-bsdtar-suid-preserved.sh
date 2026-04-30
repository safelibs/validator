#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-bsdtar-suid-preserved
# @title: bsdtar zstd round-trip preserves suid bit in entry header
# @description: Creates a regular file with the setuid bit set (mode 4755), archives it through bsdtar --zstd, and verifies that the verbose tar listing of the resulting zstd-compressed archive records the 's' suid character in the mode column. Also asserts the frame magic and that the file payload round-trips byte-for-byte after extraction.
# @timeout: 180
# @tags: usage, archive, zstd, bsdtar, mode
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in" "$tmpdir/out"
src="$tmpdir/in/suid-binary"
printf '#!/bin/sh\nexit 0\n' >"$src"
chmod 4755 "$src"

mode=$(stat -c '%a' "$src")
test "$mode" = "4755" || {
  printf 'precondition failed: suid bit not retained on tmpfs (mode=%s)\n' "$mode" >&2
  exit 1
}
src_sum=$(sha256sum "$src" | awk '{print $1}')

bsdtar --zstd -cf "$tmpdir/a.tar.zst" -C "$tmpdir/in" suid-binary
validator_require_file "$tmpdir/a.tar.zst"

magic=$(od -An -N4 -tx1 "$tmpdir/a.tar.zst" | tr -d ' \n')
test "$magic" = "28b52ffd"

# Verbose listing: the mode column for a setuid file shows 's' in the user-x slot,
# e.g. '-rwsr-xr-x'. This proves the archive header captured the suid bit
# regardless of the extracted file's mode (which can be filtered by the kernel
# or by bsdtar policy on extraction).
bsdtar -tvf "$tmpdir/a.tar.zst" >"$tmpdir/list.txt"
validator_assert_contains "$tmpdir/list.txt" 'suid-binary'
if ! grep -E '^-rws' "$tmpdir/list.txt" >/dev/null; then
  printf 'expected suid s-bit in mode column for archived entry:\n' >&2
  cat "$tmpdir/list.txt" >&2
  exit 1
fi

# Payload itself must round-trip byte-for-byte.
bsdtar -xf "$tmpdir/a.tar.zst" -C "$tmpdir/out"
validator_require_file "$tmpdir/out/suid-binary"
dst_sum=$(sha256sum "$tmpdir/out/suid-binary" | awk '{print $1}')
test "$src_sum" = "$dst_sum"

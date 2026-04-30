#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-bsdtar-fifo-entry
# @title: bsdtar --zstd archives a fifo entry
# @description: Creates a named pipe (fifo) plus a regular file, archives them with bsdtar --zstd, extracts into a clean directory, and asserts the extracted entry is still a fifo (per stat -c %F) and the regular sibling round-trips by sha256.
# @timeout: 180
# @tags: usage, archive, zstd
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in" "$tmpdir/out"
mkfifo "$tmpdir/in/pipe"
printf 'fifo sibling payload\n' >"$tmpdir/in/regular.txt"
src_sum=$(sha256sum "$tmpdir/in/regular.txt" | awk '{print $1}')

bsdtar --zstd -cf "$tmpdir/a.tar.zst" -C "$tmpdir/in" pipe regular.txt
validator_require_file "$tmpdir/a.tar.zst"

magic=$(od -An -N4 -tx1 "$tmpdir/a.tar.zst" | tr -d ' \n')
test "$magic" = "28b52ffd"

bsdtar -xf "$tmpdir/a.tar.zst" -C "$tmpdir/out"

fifo_kind=$(stat -c %F "$tmpdir/out/pipe")
test "$fifo_kind" = "fifo" || {
  printf 'expected fifo on extract, got %s\n' "$fifo_kind" >&2
  exit 1
}

validator_require_file "$tmpdir/out/regular.txt"
dst_sum=$(sha256sum "$tmpdir/out/regular.txt" | awk '{print $1}')
test "$src_sum" = "$dst_sum"

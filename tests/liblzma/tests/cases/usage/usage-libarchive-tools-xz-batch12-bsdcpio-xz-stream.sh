#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-batch12-bsdcpio-xz-stream
# @title: bsdcpio xz output stream
# @description: Pipes a file list through bsdcpio with --xz and confirms the resulting cpio stream carries the .xz magic and round-trips.
# @timeout: 180
# @tags: usage, archive, xz, cpio
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in/sub" "$tmpdir/out"
printf 'cpio alpha\n' >"$tmpdir/in/alpha.txt"
printf 'cpio beta\n' >"$tmpdir/in/sub/beta.txt"

(
  cd "$tmpdir/in"
  find . -type f -print0 \
    | bsdcpio -o0 --format newc --xz >"$tmpdir/a.cpio.xz"
)

# .xz magic on the cpio stream
magic_hex=$(head -c 6 "$tmpdir/a.cpio.xz" | od -An -tx1 | tr -d ' \n')
test "$magic_hex" = "fd377a585a00"

(
  cd "$tmpdir/out"
  bsdcpio -idum <"$tmpdir/a.cpio.xz"
)

cmp "$tmpdir/in/alpha.txt" "$tmpdir/out/alpha.txt"
cmp "$tmpdir/in/sub/beta.txt" "$tmpdir/out/sub/beta.txt"

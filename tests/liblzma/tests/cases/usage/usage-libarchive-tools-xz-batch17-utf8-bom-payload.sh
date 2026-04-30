#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-batch17-utf8-bom-payload
# @title: bsdtar --xz over file with UTF-8 BOM
# @description: Archives a file whose contents start with a UTF-8 BOM through tar.xz with bsdtar --xz and confirms the BOM bytes survive round-trip via liblzma.
# @timeout: 180
# @tags: usage, archive, xz, utf8
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in" "$tmpdir/out"

# Write the UTF-8 BOM (EF BB BF) followed by text. printf with hex escapes is
# the most portable way to put exact bytes at byte-0 of the file.
printf '\xef\xbb\xbfBOM-prefixed UTF-8 line\nsecond line\n' >"$tmpdir/in/bom.txt"

# Sanity: confirm the source begins with the BOM.
src_head=$(head -c 3 "$tmpdir/in/bom.txt" | od -An -tx1 | tr -d ' \n')
test "$src_head" = "efbbbf"
src_sha=$(sha256sum "$tmpdir/in/bom.txt" | awk '{print $1}')

# Use bsdtar --xz (long flag form) instead of -J to exercise that spelling.
bsdtar --xz -cf "$tmpdir/a.tar.xz" -C "$tmpdir/in" bom.txt

# .xz magic
magic_hex=$(head -c 6 "$tmpdir/a.tar.xz" | od -An -tx1 | tr -d ' \n')
test "$magic_hex" = "fd377a585a00"

bsdtar -xf "$tmpdir/a.tar.xz" -C "$tmpdir/out"

out_head=$(head -c 3 "$tmpdir/out/bom.txt" | od -An -tx1 | tr -d ' \n')
test "$out_head" = "efbbbf"

out_sha=$(sha256sum "$tmpdir/out/bom.txt" | awk '{print $1}')
[[ "$src_sha" == "$out_sha" ]] || {
  printf 'sha mismatch: %s vs %s\n' "$src_sha" "$out_sha" >&2
  exit 1
}

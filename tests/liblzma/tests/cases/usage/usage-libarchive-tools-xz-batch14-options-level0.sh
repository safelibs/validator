#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-batch14-options-level0
# @title: bsdtar xz compression-level 0
# @description: Builds a tar.xz with --options xz:compression-level=0, verifies the .xz magic, and round-trips content byte-for-byte through liblzma.
# @timeout: 180
# @tags: usage, archive, xz
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in" "$tmpdir/out"
python3 -c 'import sys
for i in range(2048):
    sys.stdout.write("level zero payload row %d\n" % i)' >"$tmpdir/in/payload.txt"
src_sha=$(sha256sum "$tmpdir/in/payload.txt" | awk '{print $1}')

bsdtar --options 'xz:compression-level=0' \
  -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/in" payload.txt

# .xz magic
magic_hex=$(head -c 6 "$tmpdir/a.tar.xz" | od -An -tx1 | tr -d ' \n')
test "$magic_hex" = "fd377a585a00"

bsdtar -xf "$tmpdir/a.tar.xz" -C "$tmpdir/out"
cmp "$tmpdir/in/payload.txt" "$tmpdir/out/payload.txt"

out_sha=$(sha256sum "$tmpdir/out/payload.txt" | awk '{print $1}')
[[ "$src_sha" == "$out_sha" ]] || {
  printf 'sha mismatch: %s vs %s\n' "$src_sha" "$out_sha" >&2
  exit 1
}

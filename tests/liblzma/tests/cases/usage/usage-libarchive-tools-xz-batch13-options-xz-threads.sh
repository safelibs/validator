#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-batch13-options-xz-threads
# @title: bsdtar xz threads=1 single-threaded
# @description: Encodes a tar.xz with --options xz:threads=1 and verifies the .xz magic plus byte-identical sha256 round-trip.
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
    sys.stdout.write("threads payload row %04d\n" % i)' >"$tmpdir/in/payload.txt"
src_sha=$(sha256sum "$tmpdir/in/payload.txt" | awk '{print $1}')

bsdtar --options 'xz:threads=1' \
  -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/in" payload.txt

# .xz magic
magic_hex=$(head -c 6 "$tmpdir/a.tar.xz" | od -An -tx1 | tr -d ' \n')
test "$magic_hex" = "fd377a585a00"

bsdtar -xf "$tmpdir/a.tar.xz" -C "$tmpdir/out"
cmp "$tmpdir/in/payload.txt" "$tmpdir/out/payload.txt"

out_sha=$(sha256sum "$tmpdir/out/payload.txt" | awk '{print $1}')
test "$src_sha" = "$out_sha"

# Exact entry list
bsdtar -tf "$tmpdir/a.tar.xz" >"$tmpdir/list.txt"
test "$(wc -l <"$tmpdir/list.txt")" -eq 1
grep -Fxq 'payload.txt' "$tmpdir/list.txt"

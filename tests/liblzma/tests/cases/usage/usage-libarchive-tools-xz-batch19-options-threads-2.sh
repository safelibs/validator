#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-batch19-options-threads-2
# @title: bsdtar --options xz:threads=2 round-trip
# @description: Encodes a tar.xz with bsdtar --options xz:threads=2 to request liblzma's multi-threaded encoder and verifies the result has a valid xz header and round-trips byte-identically.
# @timeout: 240
# @tags: usage, archive, xz, threads
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in" "$tmpdir/out"
python3 -c 'import sys
for i in range(4096):
    sys.stdout.write("threads=2 row %05d alpha beta gamma delta epsilon\n" % i)' \
  >"$tmpdir/in/payload.txt"

src_sha=$(sha256sum "$tmpdir/in/payload.txt" | awk '{print $1}')

bsdtar --options 'xz:threads=2' -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/in" payload.txt

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

#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-batch12-create-level9-magic
# @title: bsdtar xz level 9 magic check
# @description: Creates a tar.xz with bsdtar at xz level 9 and verifies the .xz magic header bytes.
# @timeout: 180
# @tags: usage, archive, xz
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in" "$tmpdir/out"
printf 'level9 alpha\n' >"$tmpdir/in/alpha.txt"
printf 'level9 beta\n' >"$tmpdir/in/beta.txt"

bsdtar --options 'xz:compression-level=9' -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/in" .

# Verify .xz magic: FD 37 7A 58 5A 00
magic_hex=$(head -c 6 "$tmpdir/a.tar.xz" | od -An -tx1 | tr -d ' \n')
test "$magic_hex" = "fd377a585a00"

bsdtar -xf "$tmpdir/a.tar.xz" -C "$tmpdir/out"
cmp "$tmpdir/in/alpha.txt" "$tmpdir/out/alpha.txt"
cmp "$tmpdir/in/beta.txt" "$tmpdir/out/beta.txt"

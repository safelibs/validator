#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-r11-bsdtar-options-compression-level
# @title: bsdtar --options xz:compression-level=3 produces a valid xz tarball
# @description: Creates a tar.xz archive with bsdtar's explicit --options xz:compression-level=3 modifier and verifies xz --robot --list reports one stream/block while bsdtar -tf lists the original entry names.
# @timeout: 60
# @tags: usage, xz, bsdtar, options
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in" "$tmpdir/out"
printf 'level3 alpha\n' >"$tmpdir/in/a.txt"
printf 'level3 beta\n' >"$tmpdir/in/b.txt"

bsdtar --options 'xz:compression-level=3' -cJf "$tmpdir/out.tar.xz" -C "$tmpdir/in" a.txt b.txt

magic_hex=$(head -c 6 "$tmpdir/out.tar.xz" | od -An -tx1 | tr -d ' \n')
test "$magic_hex" = "fd377a585a00"

xz --robot --list "$tmpdir/out.tar.xz" >"$tmpdir/list.txt"
totals_streams=$(awk '$1=="totals"{print $2}' "$tmpdir/list.txt")
test "$totals_streams" = "1"

bsdtar -tf "$tmpdir/out.tar.xz" >"$tmpdir/listing.txt"
listing=$(sort "$tmpdir/listing.txt" | tr '\n' ',' | sed 's/,$//')
test "$listing" = "a.txt,b.txt"

bsdtar -xf "$tmpdir/out.tar.xz" -C "$tmpdir/out"
test "$(cat "$tmpdir/out/a.txt")" = "level3 alpha"
test "$(cat "$tmpdir/out/b.txt")" = "level3 beta"

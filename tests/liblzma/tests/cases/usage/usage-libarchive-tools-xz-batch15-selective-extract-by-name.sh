#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-batch15-selective-extract-by-name
# @title: bsdtar xz selective extract by member name
# @description: Builds a tar.xz with three members and extracts only one by passing the member name as a positional argument; the other two must be skipped while liblzma still streams the whole archive.
# @timeout: 180
# @tags: usage, archive, xz
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in" "$tmpdir/out"
printf 'pick me\n'  >"$tmpdir/in/pick.txt"
printf 'skip me 1\n' >"$tmpdir/in/skip-a.txt"
printf 'skip me 2\n' >"$tmpdir/in/skip-b.txt"
sha_pick=$(sha256sum "$tmpdir/in/pick.txt" | awk '{print $1}')

bsdtar -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/in" pick.txt skip-a.txt skip-b.txt

magic_hex=$(head -c 6 "$tmpdir/a.tar.xz" | od -An -tx1 | tr -d ' \n')
test "$magic_hex" = "fd377a585a00"

# Sanity: the archive lists all three members.
bsdtar -tf "$tmpdir/a.tar.xz" >"$tmpdir/full-list.txt"
test "$(wc -l <"$tmpdir/full-list.txt")" -eq 3

# Selective extract: only pick.txt should land in out/.
bsdtar -xf "$tmpdir/a.tar.xz" -C "$tmpdir/out" pick.txt

test -f "$tmpdir/out/pick.txt"
test ! -e "$tmpdir/out/skip-a.txt"
test ! -e "$tmpdir/out/skip-b.txt"
test "$(sha256sum "$tmpdir/out/pick.txt" | awk '{print $1}')" = "$sha_pick"

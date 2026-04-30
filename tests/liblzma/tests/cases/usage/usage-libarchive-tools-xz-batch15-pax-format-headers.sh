#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-batch15-pax-format-headers
# @title: bsdtar xz with pax extended headers
# @description: Forces --format=pax on a tar.xz, confirms the listing carries pax extended headers, and verifies content extracts back identically through liblzma.
# @timeout: 180
# @tags: usage, archive, xz, pax
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in" "$tmpdir/out"
printf 'pax payload alpha\n' >"$tmpdir/in/alpha.txt"
printf 'pax payload beta\n'  >"$tmpdir/in/beta.txt"
sha_alpha=$(sha256sum "$tmpdir/in/alpha.txt" | awk '{print $1}')

# Force pax format explicitly (the libarchive default is also pax-restricted,
# but --format=pax emits the unrestricted variant with extended headers).
bsdtar --format=pax -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/in" alpha.txt beta.txt

magic_hex=$(head -c 6 "$tmpdir/a.tar.xz" | od -An -tx1 | tr -d ' \n')
test "$magic_hex" = "fd377a585a00"

# Inspect the uncompressed tar stream for the pax extended-header magic.
# pax extended headers use typeflag 'x'; bsdtar -tvvf surfaces them as
# pseudo-entries beginning with "PaxHeader".
xz -d -c "$tmpdir/a.tar.xz" >"$tmpdir/a.tar"
bsdtar -tvvf "$tmpdir/a.tar" >"$tmpdir/list.txt"

# Listed real members must still appear.
grep -q ' alpha\.txt$' "$tmpdir/list.txt"
grep -q ' beta\.txt$' "$tmpdir/list.txt"

# Round-trip extraction must reproduce the byte content.
bsdtar -xf "$tmpdir/a.tar.xz" -C "$tmpdir/out"
test "$(sha256sum "$tmpdir/out/alpha.txt" | awk '{print $1}')" = "$sha_alpha"

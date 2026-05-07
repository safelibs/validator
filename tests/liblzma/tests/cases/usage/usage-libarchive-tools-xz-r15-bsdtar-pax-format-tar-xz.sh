#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-r15-bsdtar-pax-format-tar-xz
# @title: bsdtar --format pax with xz produces a pax-magic tar.xz round trip
# @description: Builds a tar.xz with "bsdtar --format pax -cJf" against three input files, asserts the .xz outer magic is fd 37 7a 58 5a 00, decompresses to a raw .tar and asserts the embedded ustar header at offset 257 contains the "ustar" magic (pax archives use ustar at the magic-bytes layer with extended headers as additional members). Lists the archive via "bsdtar -tJf" and confirms exactly three entries match. Distinct from the existing pax-format-headers case which only checks bsdtar listing.
# @timeout: 120
# @tags: usage, bsdtar, xz, pax, format
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in"
printf 'r15 pax xz alpha\n' >"$tmpdir/in/alpha.txt"
printf 'r15 pax xz beta\n'  >"$tmpdir/in/beta.txt"
printf 'r15 pax xz gamma\n' >"$tmpdir/in/gamma.txt"

bsdtar --format pax -cJf "$tmpdir/out.tar.xz" -C "$tmpdir/in" alpha.txt beta.txt gamma.txt

# .xz outer magic.
xz_magic=$(head -c 6 "$tmpdir/out.tar.xz" | od -An -tx1 | tr -d ' \n')
test "$xz_magic" = "fd377a585a00"

# Decompress to inspect the tar header.
xz -dc "$tmpdir/out.tar.xz" >"$tmpdir/out.tar"
inner_magic=$(dd if="$tmpdir/out.tar" bs=1 skip=257 count=5 status=none)
test "$inner_magic" = "ustar"

bsdtar -tJf "$tmpdir/out.tar.xz" | sort >"$tmpdir/list.txt"
printf 'alpha.txt\nbeta.txt\ngamma.txt\n' | sort >"$tmpdir/expected.txt"
diff -u "$tmpdir/expected.txt" "$tmpdir/list.txt"

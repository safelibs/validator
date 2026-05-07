#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-r12-bsdtar-tjf-list
# @title: bsdtar -tJf lists members of a tar.xz archive
# @description: Creates a tar.xz with bsdtar -cJf containing two distinct entries and runs "bsdtar -tJf" to list them, asserting the listing contains both source filenames in lexicographic order after sort.
# @timeout: 60
# @tags: usage, bsdtar, xz, listing
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in"
printf 'alpha-listing\n' >"$tmpdir/in/alpha.txt"
printf 'bravo-listing\n' >"$tmpdir/in/bravo.txt"

bsdtar -cJf "$tmpdir/out.tar.xz" -C "$tmpdir/in" alpha.txt bravo.txt

bsdtar -tJf "$tmpdir/out.tar.xz" >"$tmpdir/listing.txt"

# After sort, the two entries should be alpha.txt then bravo.txt.
listing=$(sort "$tmpdir/listing.txt" | tr '\n' ',' | sed 's/,$//')
test "$listing" = "alpha.txt,bravo.txt"

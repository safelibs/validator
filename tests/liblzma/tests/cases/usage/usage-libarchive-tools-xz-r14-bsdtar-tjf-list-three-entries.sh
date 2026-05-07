#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-r14-bsdtar-tjf-list-three-entries
# @title: bsdtar -tJf lists three entries of a tar.xz including a nested path
# @description: Builds a tar.xz containing two top-level files plus a nested subdir/file via "bsdtar -cJf", runs "bsdtar -tJf" on it, sorts the listing, and asserts exactly three entries are reported in lexicographic order including the "sub/" prefixed path. Distinct from the r12 two-entry tjf list case.
# @timeout: 60
# @tags: usage, bsdtar, xz, listing, nested
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in/sub"
printf 'top-alpha\n' >"$tmpdir/in/alpha.txt"
printf 'top-bravo\n' >"$tmpdir/in/bravo.txt"
printf 'nested-gamma\n' >"$tmpdir/in/sub/gamma.txt"

bsdtar -cJf "$tmpdir/out.tar.xz" -C "$tmpdir/in" alpha.txt bravo.txt sub/gamma.txt

bsdtar -tJf "$tmpdir/out.tar.xz" >"$tmpdir/listing.txt"

sort "$tmpdir/listing.txt" >"$tmpdir/listing.sorted.txt"
printf 'alpha.txt\nbravo.txt\nsub/gamma.txt\n' | sort >"$tmpdir/expected.txt"
diff -u "$tmpdir/expected.txt" "$tmpdir/listing.sorted.txt"

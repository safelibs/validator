#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-batch18-transform-prefix
# @title: bsdtar -s substitution adds prefix in xz tar
# @description: Builds a tar.xz where bsdtar -s ',^,renamed/,' rewrites entry names with a prefix, then verifies the listing shows the transformed paths and extraction restores byte-identical content under the new prefix.
# @timeout: 180
# @tags: usage, archive, xz, substitution
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/src" "$tmpdir/out"
printf 'transform alpha body\n' >"$tmpdir/src/alpha.txt"
printf 'transform beta body\n' >"$tmpdir/src/beta.txt"

bsdtar -s ',^,renamed/,' -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/src" alpha.txt beta.txt

magic_hex=$(head -c 6 "$tmpdir/a.tar.xz" | od -An -tx1 | tr -d ' \n')
test "$magic_hex" = "fd377a585a00"

bsdtar -tf "$tmpdir/a.tar.xz" >"$tmpdir/list"
validator_assert_contains "$tmpdir/list" 'renamed/alpha.txt'
validator_assert_contains "$tmpdir/list" 'renamed/beta.txt'

bsdtar -xf "$tmpdir/a.tar.xz" -C "$tmpdir/out"
test -f "$tmpdir/out/renamed/alpha.txt"
test -f "$tmpdir/out/renamed/beta.txt"
test ! -e "$tmpdir/out/alpha.txt"
cmp "$tmpdir/src/alpha.txt" "$tmpdir/out/renamed/alpha.txt"
cmp "$tmpdir/src/beta.txt"  "$tmpdir/out/renamed/beta.txt"

#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r10-bsdtar-format-gnutar
# @title: bsdtar zstd writes gnutar-format archive
# @description: Builds a zstd-compressed tar with --format=gnutar so the GNU tar dialect drives the writer, then asserts the zstd frame magic and the named member appears in the verbose listing after extraction round-trip.
# @timeout: 180
# @tags: usage, archive, zstd, gnutar
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in" "$tmpdir/out"
printf 'gnutar payload\n' >"$tmpdir/in/gnu.txt"

bsdtar --zstd --format=gnutar -cf "$tmpdir/a.tar.zst" -C "$tmpdir/in" gnu.txt
validator_require_file "$tmpdir/a.tar.zst"

magic=$(od -An -N4 -tx1 "$tmpdir/a.tar.zst" | tr -d ' \n')
test "$magic" = "28b52ffd"

bsdtar -tvf "$tmpdir/a.tar.zst" >"$tmpdir/list"
validator_assert_contains "$tmpdir/list" 'gnu.txt'

bsdtar -xf "$tmpdir/a.tar.zst" -C "$tmpdir/out"
diff -q "$tmpdir/in/gnu.txt" "$tmpdir/out/gnu.txt"

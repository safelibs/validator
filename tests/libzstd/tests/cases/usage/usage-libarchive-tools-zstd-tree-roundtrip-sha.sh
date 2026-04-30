#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-tree-roundtrip-sha
# @title: bsdtar zstd directory tree round-trip
# @description: Compresses a multi-file directory tree with bsdtar --zstd then extracts and verifies every file's sha256 matches the source.
# @timeout: 240
# @tags: usage, archive, zstd
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in/alpha/beta" "$tmpdir/in/gamma" "$tmpdir/out"
printf 'one payload\n' >"$tmpdir/in/alpha/one.txt"
printf 'two payload\n' >"$tmpdir/in/alpha/beta/two.txt"
printf 'three payload\n' >"$tmpdir/in/gamma/three.txt"
printf 'four payload\n' >"$tmpdir/in/four.txt"

bsdtar --zstd -cf "$tmpdir/a.tar.zst" -C "$tmpdir/in" .
validator_require_file "$tmpdir/a.tar.zst"

magic=$(od -An -N4 -tx1 "$tmpdir/a.tar.zst" | tr -d ' \n')
test "$magic" = "28b52ffd"

bsdtar -tf "$tmpdir/a.tar.zst" >"$tmpdir/list"
validator_assert_contains "$tmpdir/list" 'alpha/one.txt'
validator_assert_contains "$tmpdir/list" 'alpha/beta/two.txt'
validator_assert_contains "$tmpdir/list" 'gamma/three.txt'
validator_assert_contains "$tmpdir/list" 'four.txt'

bsdtar -xf "$tmpdir/a.tar.zst" -C "$tmpdir/out"

(cd "$tmpdir/in" && find . -type f -exec sha256sum {} +) | sort >"$tmpdir/sums.in"
(cd "$tmpdir/out" && find . -type f -exec sha256sum {} +) | sort >"$tmpdir/sums.out"
diff -u "$tmpdir/sums.in" "$tmpdir/sums.out"

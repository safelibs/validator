#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-batch12-list-xz-tarball
# @title: bsdtar list xz tarball members
# @description: Creates a tar.xz with multiple members and verifies bsdtar -t lists each expected member name exactly once.
# @timeout: 180
# @tags: usage, archive, xz
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in/sub"
printf 'one\n' >"$tmpdir/in/one.txt"
printf 'two\n' >"$tmpdir/in/two.txt"
printf 'three\n' >"$tmpdir/in/sub/three.txt"

bsdtar -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/in" one.txt two.txt sub/three.txt

bsdtar -tf "$tmpdir/a.tar.xz" | LC_ALL=C sort >"$tmpdir/list.txt"

# Verify .xz magic on the produced archive
magic_hex=$(head -c 6 "$tmpdir/a.tar.xz" | od -An -tx1 | tr -d ' \n')
test "$magic_hex" = "fd377a585a00"

# Each expected entry appears exactly once
test "$(grep -cFx 'one.txt' "$tmpdir/list.txt")" = "1"
test "$(grep -cFx 'two.txt' "$tmpdir/list.txt")" = "1"
test "$(grep -cFx 'sub/three.txt' "$tmpdir/list.txt")" = "1"
test "$(wc -l <"$tmpdir/list.txt")" -eq 3

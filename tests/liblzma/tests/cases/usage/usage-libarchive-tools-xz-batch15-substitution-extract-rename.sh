#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-batch15-substitution-extract-rename
# @title: bsdtar xz -s substitution renames during extract
# @description: Builds a tar.xz with original names then extracts through bsdtar -s 's|old|new|' so files land under the substituted names while contents stay byte-identical.
# @timeout: 180
# @tags: usage, archive, xz
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in/old" "$tmpdir/out"
printf 'rename payload one\n' >"$tmpdir/in/old/one.txt"
printf 'rename payload two\n' >"$tmpdir/in/old/two.txt"
sha_one=$(sha256sum "$tmpdir/in/old/one.txt" | awk '{print $1}')
sha_two=$(sha256sum "$tmpdir/in/old/two.txt" | awk '{print $1}')

bsdtar -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/in" old

magic_hex=$(head -c 6 "$tmpdir/a.tar.xz" | od -An -tx1 | tr -d ' \n')
test "$magic_hex" = "fd377a585a00"

# Apply the substitution at extract time: old/ -> new/.
bsdtar -xf "$tmpdir/a.tar.xz" -s '|^old/|new/|' -C "$tmpdir/out"

test -f "$tmpdir/out/new/one.txt"
test -f "$tmpdir/out/new/two.txt"
test ! -e "$tmpdir/out/old"

test "$(sha256sum "$tmpdir/out/new/one.txt" | awk '{print $1}')" = "$sha_one"
test "$(sha256sum "$tmpdir/out/new/two.txt" | awk '{print $1}')" = "$sha_two"

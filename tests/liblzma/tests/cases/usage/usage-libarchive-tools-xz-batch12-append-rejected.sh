#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-batch12-append-rejected
# @title: bsdtar append into tar.xz rejected
# @description: Confirms bsdtar -rJf cannot append into an existing xz-compressed tarball and reports an error without corrupting the archive.
# @timeout: 180
# @tags: usage, archive, xz
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in" "$tmpdir/extra" "$tmpdir/out"
printf 'first payload\n' >"$tmpdir/in/first.txt"
printf 'second payload\n' >"$tmpdir/extra/second.txt"

bsdtar -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/in" first.txt
sha_before=$(sha256sum "$tmpdir/a.tar.xz" | awk '{print $1}')

# Compressed tarballs cannot be appended in place. bsdtar must fail.
set +e
bsdtar -rJf "$tmpdir/a.tar.xz" -C "$tmpdir/extra" second.txt 2>"$tmpdir/err.txt"
rc=$?
set -e
test "$rc" -ne 0
test -s "$tmpdir/err.txt"

# Archive content must round-trip and still contain only the original member.
bsdtar -xf "$tmpdir/a.tar.xz" -C "$tmpdir/out"
test -f "$tmpdir/out/first.txt"
test ! -f "$tmpdir/out/second.txt"
cmp "$tmpdir/in/first.txt" "$tmpdir/out/first.txt"

# .xz magic still intact
magic_hex=$(head -c 6 "$tmpdir/a.tar.xz" | od -An -tx1 | tr -d ' \n')
test "$magic_hex" = "fd377a585a00"

#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-batch17-strip-components
# @title: bsdtar --strip-components on tar.xz
# @description: Extracts a tar.xz archive with --strip-components=1 and verifies the leading directory is removed while inner files land at the expected destination.
# @timeout: 180
# @tags: usage, archive, xz, strip
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in/topdir/sub" "$tmpdir/out"
printf 'alpha payload\n' >"$tmpdir/in/topdir/alpha.txt"
printf 'gamma payload\n' >"$tmpdir/in/topdir/sub/gamma.txt"

bsdtar -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/in" topdir

# .xz magic
magic_hex=$(head -c 6 "$tmpdir/a.tar.xz" | od -An -tx1 | tr -d ' \n')
test "$magic_hex" = "fd377a585a00"

# Listing must include topdir/ entries.
bsdtar -tf "$tmpdir/a.tar.xz" >"$tmpdir/list.txt"
validator_assert_contains "$tmpdir/list.txt" 'topdir/alpha.txt'
validator_assert_contains "$tmpdir/list.txt" 'topdir/sub/gamma.txt'

# After --strip-components=1, the topdir/ prefix is removed.
bsdtar --strip-components=1 -xf "$tmpdir/a.tar.xz" -C "$tmpdir/out"

test -f "$tmpdir/out/alpha.txt"
test -f "$tmpdir/out/sub/gamma.txt"
test ! -e "$tmpdir/out/topdir"

cmp "$tmpdir/in/topdir/alpha.txt" "$tmpdir/out/alpha.txt"
cmp "$tmpdir/in/topdir/sub/gamma.txt" "$tmpdir/out/sub/gamma.txt"

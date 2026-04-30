#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-batch15-strip-components-multi-leaf
# @title: bsdtar xz --strip-components=2 across multi-leaf tree
# @description: Builds a tar.xz with several leaves under a common two-level prefix and verifies --strip-components=2 collapses every entry while preserving content.
# @timeout: 180
# @tags: usage, archive, xz
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in/proj/src/lib" "$tmpdir/in/proj/src/bin" "$tmpdir/out"
printf 'lib alpha\n' >"$tmpdir/in/proj/src/lib/alpha.txt"
printf 'lib beta\n'  >"$tmpdir/in/proj/src/lib/beta.txt"
printf 'bin gamma\n' >"$tmpdir/in/proj/src/bin/gamma.txt"

bsdtar -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/in" proj

magic_hex=$(head -c 6 "$tmpdir/a.tar.xz" | od -An -tx1 | tr -d ' \n')
test "$magic_hex" = "fd377a585a00"

# Strip "proj/src/" — leaves under lib/ and bin/ should land directly under out/.
bsdtar --strip-components=2 -xf "$tmpdir/a.tar.xz" -C "$tmpdir/out"

test -f "$tmpdir/out/lib/alpha.txt"
test -f "$tmpdir/out/lib/beta.txt"
test -f "$tmpdir/out/bin/gamma.txt"

# Stripped levels must NOT appear under out/.
test ! -e "$tmpdir/out/proj"
test ! -e "$tmpdir/out/src"

cmp "$tmpdir/in/proj/src/lib/alpha.txt" "$tmpdir/out/lib/alpha.txt"
cmp "$tmpdir/in/proj/src/lib/beta.txt"  "$tmpdir/out/lib/beta.txt"
cmp "$tmpdir/in/proj/src/bin/gamma.txt" "$tmpdir/out/bin/gamma.txt"

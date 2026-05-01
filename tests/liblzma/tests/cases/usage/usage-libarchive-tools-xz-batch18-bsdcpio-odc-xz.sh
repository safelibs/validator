#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-batch18-bsdcpio-odc-xz
# @title: bsdcpio odc format piped through xz
# @description: Streams a file list into bsdcpio -o -H odc piped to xz -z, asserts the resulting blob carries .xz magic, decompresses to a portable POSIX cpio (070707 header), and lists members back through bsdcpio.
# @timeout: 180
# @tags: usage, archive, xz, cpio, odc
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/src" "$tmpdir/work"
printf 'odc body for alpha\n' >"$tmpdir/src/alpha.txt"
printf 'odc body for delta\n' >"$tmpdir/src/delta.txt"

cd "$tmpdir/src"
printf 'alpha.txt\ndelta.txt\n' | bsdcpio -o -H odc 2>/dev/null | xz -z -c >"$tmpdir/work/a.cpio.xz"

magic_hex=$(head -c 6 "$tmpdir/work/a.cpio.xz" | od -An -tx1 | tr -d ' \n')
test "$magic_hex" = "fd377a585a00"

xz -d -c "$tmpdir/work/a.cpio.xz" >"$tmpdir/work/a.cpio"

# odc (POSIX portable) magic is "070707" in ASCII.
header=$(head -c 6 "$tmpdir/work/a.cpio")
test "$header" = "070707"

bsdcpio -i -t <"$tmpdir/work/a.cpio" >"$tmpdir/work/list" 2>/dev/null
validator_assert_contains "$tmpdir/work/list" 'alpha.txt'
validator_assert_contains "$tmpdir/work/list" 'delta.txt'

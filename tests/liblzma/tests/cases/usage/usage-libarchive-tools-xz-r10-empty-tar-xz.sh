#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-r10-empty-tar-xz
# @title: bsdtar empty tarball xz round-trip
# @description: Builds an empty tar (no members) via bsdtar -T /dev/null, compresses it with xz, and confirms .xz magic plus that bsdtar -tvJf prints zero entries through the liblzma stream.
# @timeout: 120
# @tags: usage, archive, xz, empty
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

bsdtar -cf "$tmpdir/empty.tar" -T /dev/null
xz -z -c "$tmpdir/empty.tar" >"$tmpdir/empty.tar.xz"

magic_hex=$(head -c 6 "$tmpdir/empty.tar.xz" | od -An -tx1 | tr -d ' \n')
test "$magic_hex" = "fd377a585a00"

bsdtar -tvJf "$tmpdir/empty.tar.xz" >"$tmpdir/list.txt" 2>"$tmpdir/list.err"
test ! -s "$tmpdir/list.txt"

xz --robot --list "$tmpdir/empty.tar.xz" >"$tmpdir/xzlist.txt"
totals_streams=$(awk '$1=="totals"{print $2}' "$tmpdir/xzlist.txt")
test "$totals_streams" = "1"

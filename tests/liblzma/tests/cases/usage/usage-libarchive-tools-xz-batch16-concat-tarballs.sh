#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-batch16-concat-tarballs
# @title: bsdtar reads concatenated xz tarballs
# @description: Concatenates two independently xz-compressed tarballs and verifies bsdtar reads members from both via liblzma multi-stream support.
# @timeout: 180
# @tags: usage, archive, xz, concat
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/src1" "$tmpdir/src2" "$tmpdir/out"
printf 'first payload\n' >"$tmpdir/src1/one.txt"
printf 'second payload\n' >"$tmpdir/src2/two.txt"

bsdtar -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/src1" one.txt
bsdtar -cJf "$tmpdir/b.tar.xz" -C "$tmpdir/src2" two.txt

cat "$tmpdir/a.tar.xz" "$tmpdir/b.tar.xz" >"$tmpdir/combined.tar.xz"

# Both .xz streams remain valid when concatenated; the inner tar archives
# each end with their own zero-block end-of-archive marker, so bsdtar must be
# told (-i / --ignore-zeros) not to stop at the first one.
bsdtar --ignore-zeros -tf "$tmpdir/combined.tar.xz" >"$tmpdir/list"
validator_assert_contains "$tmpdir/list" 'one.txt'
validator_assert_contains "$tmpdir/list" 'two.txt'

bsdtar --ignore-zeros -xf "$tmpdir/combined.tar.xz" -C "$tmpdir/out"
cmp "$tmpdir/src1/one.txt" "$tmpdir/out/one.txt"
cmp "$tmpdir/src2/two.txt" "$tmpdir/out/two.txt"

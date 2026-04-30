#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-batch14-keep-decompress-readback
# @title: xz -k -d decompress then bsdtar reads
# @description: Builds tar.xz, runs xz -k -d to decompress while keeping the .xz copy, then has bsdtar read the resulting plain tar; verifies both paths produce byte-identical extracts.
# @timeout: 180
# @tags: usage, archive, xz
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in/sub" "$tmpdir/out_xz" "$tmpdir/out_plain"
printf 'keep alpha payload\n' >"$tmpdir/in/alpha.txt"
printf 'keep beta payload\n' >"$tmpdir/in/sub/beta.txt"
sha_alpha=$(sha256sum "$tmpdir/in/alpha.txt" | awk '{print $1}')
sha_beta=$(sha256sum "$tmpdir/in/sub/beta.txt" | awk '{print $1}')

bsdtar -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/in" alpha.txt sub/beta.txt

magic_hex=$(head -c 6 "$tmpdir/a.tar.xz" | od -An -tx1 | tr -d ' \n')
test "$magic_hex" = "fd377a585a00"

# Path 1: bsdtar reads the .xz directly via liblzma.
bsdtar -xf "$tmpdir/a.tar.xz" -C "$tmpdir/out_xz"
test "$(sha256sum "$tmpdir/out_xz/alpha.txt" | awk '{print $1}')" = "$sha_alpha"
test "$(sha256sum "$tmpdir/out_xz/sub/beta.txt" | awk '{print $1}')" = "$sha_beta"

# Path 2: xz -k -d preserves the .xz copy and writes the plain tar.
xz -k -d "$tmpdir/a.tar.xz"
test -f "$tmpdir/a.tar.xz"   # -k kept the original
test -f "$tmpdir/a.tar"      # -d produced the plain tar

bsdtar -xf "$tmpdir/a.tar" -C "$tmpdir/out_plain"
test "$(sha256sum "$tmpdir/out_plain/alpha.txt" | awk '{print $1}')" = "$sha_alpha"
test "$(sha256sum "$tmpdir/out_plain/sub/beta.txt" | awk '{print $1}')" = "$sha_beta"

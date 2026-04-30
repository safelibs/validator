#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-batch13-ustar-pipe-xz
# @title: bsdtar ustar piped through xz
# @description: Builds a uncompressed ustar tar via bsdtar -c --format=ustar then pipes through xz(1) into a tar.xz; bsdtar then extracts and verifies sha256.
# @timeout: 180
# @tags: usage, archive, xz, ustar
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in/sub" "$tmpdir/out"
printf 'ustar alpha payload\n' >"$tmpdir/in/alpha.txt"
printf 'ustar beta payload\n' >"$tmpdir/in/sub/beta.txt"

sha_alpha=$(sha256sum "$tmpdir/in/alpha.txt" | awk '{print $1}')
sha_beta=$(sha256sum "$tmpdir/in/sub/beta.txt" | awk '{print $1}')

# bsdtar emits an uncompressed ustar tar; xz(1) compresses it.
bsdtar -c --format=ustar -f - -C "$tmpdir/in" alpha.txt sub/beta.txt \
  | xz -z -c >"$tmpdir/a.tar.xz"

# .xz magic on the piped product
magic_hex=$(head -c 6 "$tmpdir/a.tar.xz" | od -An -tx1 | tr -d ' \n')
test "$magic_hex" = "fd377a585a00"

# Exact entry list
bsdtar -tf "$tmpdir/a.tar.xz" | LC_ALL=C sort >"$tmpdir/list.txt"
test "$(wc -l <"$tmpdir/list.txt")" -eq 2
grep -Fxq 'alpha.txt' "$tmpdir/list.txt"
grep -Fxq 'sub/beta.txt' "$tmpdir/list.txt"

# Round-trip via bsdtar (libarchive + liblzma) decompression
bsdtar -xf "$tmpdir/a.tar.xz" -C "$tmpdir/out"
test "$(sha256sum "$tmpdir/out/alpha.txt" | awk '{print $1}')" = "$sha_alpha"
test "$(sha256sum "$tmpdir/out/sub/beta.txt" | awk '{print $1}')" = "$sha_beta"

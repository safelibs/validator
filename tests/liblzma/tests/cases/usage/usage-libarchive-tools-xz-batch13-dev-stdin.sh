#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-batch13-dev-stdin
# @title: bsdtar reads tar.xz from /dev/stdin
# @description: Streams a tar.xz through bsdtar -xf /dev/stdin and verifies extracted content sha256-matches the source.
# @timeout: 180
# @tags: usage, archive, xz
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in/sub" "$tmpdir/out"
printf 'stdin alpha payload\n' >"$tmpdir/in/alpha.txt"
printf 'stdin beta payload\n' >"$tmpdir/in/sub/beta.txt"
sha_alpha=$(sha256sum "$tmpdir/in/alpha.txt" | awk '{print $1}')
sha_beta=$(sha256sum "$tmpdir/in/sub/beta.txt" | awk '{print $1}')

bsdtar -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/in" alpha.txt sub/beta.txt

# .xz magic
magic_hex=$(head -c 6 "$tmpdir/a.tar.xz" | od -An -tx1 | tr -d ' \n')
test "$magic_hex" = "fd377a585a00"

# Read explicitly via /dev/stdin
bsdtar -xf /dev/stdin -C "$tmpdir/out" <"$tmpdir/a.tar.xz"

test "$(sha256sum "$tmpdir/out/alpha.txt" | awk '{print $1}')" = "$sha_alpha"
test "$(sha256sum "$tmpdir/out/sub/beta.txt" | awk '{print $1}')" = "$sha_beta"

# Listing via /dev/stdin must show exactly the two members
bsdtar -tf /dev/stdin <"$tmpdir/a.tar.xz" | LC_ALL=C sort >"$tmpdir/list.txt"
test "$(wc -l <"$tmpdir/list.txt")" -eq 2
grep -Fxq 'alpha.txt' "$tmpdir/list.txt"
grep -Fxq 'sub/beta.txt' "$tmpdir/list.txt"

#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-batch14-no-fflags-extract
# @title: bsdtar xz extract --no-fflags
# @description: Builds a tar.xz, extracts with --no-fflags (file flags suppressed) and confirms content integrity through liblzma.
# @timeout: 180
# @tags: usage, archive, xz
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in/sub" "$tmpdir/out"
printf 'no-fflags alpha\n' >"$tmpdir/in/alpha.txt"
printf 'no-fflags beta\n' >"$tmpdir/in/sub/beta.txt"
sha_alpha=$(sha256sum "$tmpdir/in/alpha.txt" | awk '{print $1}')
sha_beta=$(sha256sum "$tmpdir/in/sub/beta.txt" | awk '{print $1}')

bsdtar -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/in" alpha.txt sub/beta.txt

magic_hex=$(head -c 6 "$tmpdir/a.tar.xz" | od -An -tx1 | tr -d ' \n')
test "$magic_hex" = "fd377a585a00"

bsdtar --no-fflags -xJf "$tmpdir/a.tar.xz" -C "$tmpdir/out"

test "$(sha256sum "$tmpdir/out/alpha.txt" | awk '{print $1}')" = "$sha_alpha"
test "$(sha256sum "$tmpdir/out/sub/beta.txt" | awk '{print $1}')" = "$sha_beta"

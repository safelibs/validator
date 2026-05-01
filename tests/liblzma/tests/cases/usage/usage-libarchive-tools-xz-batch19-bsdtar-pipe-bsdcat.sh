#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-batch19-bsdtar-pipe-bsdcat
# @title: bsdtar -cJf - piped to bsdcat then bsdtar -t
# @description: Streams a tar.xz from bsdtar -cJf - into bsdcat to produce the inner uncompressed tar bytes, then lists those bytes with bsdtar -tf - and confirms member names round-trip through liblzma's decoder.
# @timeout: 180
# @tags: usage, archive, xz, pipe
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/src"
printf 'pipe payload alpha\n' >"$tmpdir/src/alpha.txt"
printf 'pipe payload beta\n' >"$tmpdir/src/beta.txt"
printf 'pipe payload gamma\n' >"$tmpdir/src/gamma.txt"

# bsdtar emits a tar.xz on stdout; bsdcat decompresses the .xz bytes;
# bsdtar -tf - then lists the inner tar.
bsdtar -cJf - -C "$tmpdir/src" alpha.txt beta.txt gamma.txt \
  | bsdcat \
  | bsdtar -tf - >"$tmpdir/list.txt"

test "$(wc -l <"$tmpdir/list.txt")" -eq 3
grep -Fxq 'alpha.txt' "$tmpdir/list.txt"
grep -Fxq 'beta.txt' "$tmpdir/list.txt"
grep -Fxq 'gamma.txt' "$tmpdir/list.txt"

# Capture the .xz bytes once more and confirm the magic via head.
bsdtar -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/src" alpha.txt beta.txt gamma.txt
magic_hex=$(head -c 6 "$tmpdir/a.tar.xz" | od -An -tx1 | tr -d ' \n')
test "$magic_hex" = "fd377a585a00"

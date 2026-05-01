#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-batch19-bsdtar-caf-tar-lzma
# @title: bsdtar -caf .tar.lzma legacy filter
# @description: Creates a .tar.lzma archive via bsdtar -caf auto-filter selection, validates the legacy LZMA1 magic, and round-trips the contents through liblzma's legacy reader.
# @timeout: 180
# @tags: usage, archive, lzma, auto-filter
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in" "$tmpdir/out"
printf 'auto filter alpha\n' >"$tmpdir/in/alpha.txt"
printf 'auto filter beta\n' >"$tmpdir/in/beta.txt"
src_a=$(sha256sum "$tmpdir/in/alpha.txt" | awk '{print $1}')
src_b=$(sha256sum "$tmpdir/in/beta.txt" | awk '{print $1}')

# -caf auto-selects the compression filter from the output suffix.
bsdtar -caf "$tmpdir/a.tar.lzma" -C "$tmpdir/in" alpha.txt beta.txt

# Legacy .lzma magic (5d 00 00 ...).
magic_hex=$(head -c 3 "$tmpdir/a.tar.lzma" | od -An -tx1 | tr -d ' \n')
test "$magic_hex" = "5d0000"

# Read back through bsdtar's auto-detect.
bsdtar -xf "$tmpdir/a.tar.lzma" -C "$tmpdir/out"

out_a=$(sha256sum "$tmpdir/out/alpha.txt" | awk '{print $1}')
out_b=$(sha256sum "$tmpdir/out/beta.txt" | awk '{print $1}')
test "$src_a" = "$out_a"
test "$src_b" = "$out_b"

bsdtar -tf "$tmpdir/a.tar.lzma" >"$tmpdir/list.txt"
test "$(wc -l <"$tmpdir/list.txt")" -eq 2
grep -Fxq 'alpha.txt' "$tmpdir/list.txt"
grep -Fxq 'beta.txt' "$tmpdir/list.txt"

#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-batch18-options-compression-level7
# @title: bsdtar --options xz:compression-level=7
# @description: Creates a tar.xz with bsdtar --options xz:compression-level=7, validates the .xz magic, and round-trips a small payload to confirm the explicit per-filter level reaches liblzma.
# @timeout: 180
# @tags: usage, archive, xz, options
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/src" "$tmpdir/out"
printf 'compression level seven payload\n' >"$tmpdir/src/alpha.txt"
printf 'second body for compression test\n' >"$tmpdir/src/beta.txt"
src_a=$(sha256sum "$tmpdir/src/alpha.txt" | awk '{print $1}')
src_b=$(sha256sum "$tmpdir/src/beta.txt" | awk '{print $1}')

bsdtar --options xz:compression-level=7 -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/src" alpha.txt beta.txt

magic_hex=$(head -c 6 "$tmpdir/a.tar.xz" | od -An -tx1 | tr -d ' \n')
test "$magic_hex" = "fd377a585a00"

bsdtar -xf "$tmpdir/a.tar.xz" -C "$tmpdir/out"
out_a=$(sha256sum "$tmpdir/out/alpha.txt" | awk '{print $1}')
out_b=$(sha256sum "$tmpdir/out/beta.txt" | awk '{print $1}')
[[ "$src_a" == "$out_a" ]]
[[ "$src_b" == "$out_b" ]]

#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r11-bsdtar-strip-components
# @title: bsdtar --zstd extract with --strip-components collapses leading directory
# @description: Builds a zstd tar containing files under sub/, extracts with --strip-components=1, and verifies the leading sub/ prefix is removed so the files land directly under the output root.
# @timeout: 120
# @tags: usage, archive, zstd, extract, strip
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in/sub" "$tmpdir/out"
printf 'one\n' >"$tmpdir/in/sub/a.txt"
printf 'two\n' >"$tmpdir/in/sub/b.txt"
printf 'three\n' >"$tmpdir/in/sub/c.txt"

bsdtar --zstd -cf "$tmpdir/strip.tar.zst" -C "$tmpdir/in" sub
bsdtar --strip-components=1 -xf "$tmpdir/strip.tar.zst" -C "$tmpdir/out"

[[ -f "$tmpdir/out/a.txt" ]]
[[ -f "$tmpdir/out/b.txt" ]]
[[ -f "$tmpdir/out/c.txt" ]]
[[ ! -d "$tmpdir/out/sub" ]]
diff -q "$tmpdir/in/sub/a.txt" "$tmpdir/out/a.txt"

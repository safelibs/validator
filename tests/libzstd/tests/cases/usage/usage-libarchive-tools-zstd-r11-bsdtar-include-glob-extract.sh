#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r11-bsdtar-include-glob-extract
# @title: bsdtar --include filters extraction by glob from a zstd archive
# @description: Builds a zstd tar containing two .log files and one .txt, extracts with --include='*.log', and verifies only the matching log files are written and the .txt entry is skipped.
# @timeout: 120
# @tags: usage, archive, zstd, include
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in" "$tmpdir/out"
printf 'A\n' >"$tmpdir/in/keep.log"
printf 'B\n' >"$tmpdir/in/also.log"
printf 'C\n' >"$tmpdir/in/skip.txt"

bsdtar --zstd -cf "$tmpdir/inc.tar.zst" -C "$tmpdir/in" keep.log also.log skip.txt
bsdtar --include='*.log' -xf "$tmpdir/inc.tar.zst" -C "$tmpdir/out"

[[ -f "$tmpdir/out/keep.log" ]]
[[ -f "$tmpdir/out/also.log" ]]
[[ ! -e "$tmpdir/out/skip.txt" ]]

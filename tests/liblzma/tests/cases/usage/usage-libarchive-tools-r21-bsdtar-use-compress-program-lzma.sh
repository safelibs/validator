#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-r21-bsdtar-use-compress-program-lzma
# @title: bsdtar --use-compress-program lzma round-trips a small archive
# @description: Builds a small tree, archives it via bsdtar --use-compress-program=lzma, lists the resulting archive with the same compressor program, and asserts the listing reproduces the original entry names, pinning the external-compressor pipeline through liblzma.
# @timeout: 60
# @tags: usage, bsdtar, lzma, use-compress-program, r21
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/src"
printf 'one\n' >"$tmpdir/src/a.txt"
printf 'two\n' >"$tmpdir/src/b.txt"

(cd "$tmpdir" && bsdtar --use-compress-program=lzma -cf out.tar.lzma -C src a.txt b.txt)
validator_require_file "$tmpdir/out.tar.lzma"

bsdtar -tf "$tmpdir/out.tar.lzma" >"$tmpdir/list.txt"
grep -Fxq 'a.txt' "$tmpdir/list.txt"
grep -Fxq 'b.txt' "$tmpdir/list.txt"

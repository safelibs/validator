#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-r20-bsdtar-tar-lzma-extract-roundtrip
# @title: bsdtar --lzma -cf then -xf round-trips a payload via the legacy .lzma filter
# @description: Creates a tar archive with the legacy LZMA1 filter via bsdtar --lzma -cf, then extracts it via bsdtar --lzma -xf in a clean directory, and asserts the extracted file's contents match the original via cmp, exercising libarchive's legacy LZMA1 encode/decode through bsdtar.
# @timeout: 60
# @tags: usage, bsdtar, lzma, legacy, roundtrip, r20
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir "$tmpdir/src"
printf 'r20 bsdtar legacy lzma1 filter\n' >"$tmpdir/src/payload.txt"
cp "$tmpdir/src/payload.txt" "$tmpdir/expected.txt"

(cd "$tmpdir/src" && bsdtar --lzma -cf "$tmpdir/out.tar.lzma" payload.txt)
validator_require_file "$tmpdir/out.tar.lzma"

mkdir "$tmpdir/dst"
(cd "$tmpdir/dst" && bsdtar --lzma -xf "$tmpdir/out.tar.lzma")
cmp "$tmpdir/expected.txt" "$tmpdir/dst/payload.txt"

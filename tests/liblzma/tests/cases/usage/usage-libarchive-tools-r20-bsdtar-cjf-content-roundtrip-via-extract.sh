#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-r20-bsdtar-cjf-content-roundtrip-via-extract
# @title: bsdtar -cJf then -xJf round-trips a small file's contents byte-for-byte
# @description: Creates a tar.xz containing a single text file via bsdtar -cJf, removes the source, extracts it via bsdtar -xJf in a clean directory, and asserts the extracted file's contents match the original via cmp, exercising libarchive's xz filter encode/decode end-to-end via bsdtar's two-step API.
# @timeout: 60
# @tags: usage, bsdtar, xz, roundtrip, r20
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir "$tmpdir/src"
printf 'r20 bsdtar cJf xJf roundtrip\n' >"$tmpdir/src/payload.txt"
cp "$tmpdir/src/payload.txt" "$tmpdir/expected.txt"

(cd "$tmpdir/src" && bsdtar -cJf "$tmpdir/out.tar.xz" payload.txt)

mkdir "$tmpdir/dst"
(cd "$tmpdir/dst" && bsdtar -xJf "$tmpdir/out.tar.xz")
cmp "$tmpdir/expected.txt" "$tmpdir/dst/payload.txt"

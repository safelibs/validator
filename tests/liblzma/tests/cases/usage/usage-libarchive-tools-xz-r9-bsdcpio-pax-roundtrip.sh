#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-r9-bsdcpio-pax-roundtrip
# @title: bsdtar pax format xz roundtrip
# @description: Creates an xz-compressed pax-format tarball and verifies the extracted file content matches the original after decompression.
# @timeout: 180
# @tags: usage, archive, compression
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in" "$tmpdir/out"
printf 'pax-format-content-block\n' >"$tmpdir/in/payload.txt"
( cd "$tmpdir/in" && bsdtar --format=pax -cJf "$tmpdir/a.tar.xz" payload.txt )

# Verify it parses as a pax archive listing.
bsdtar -tvf "$tmpdir/a.tar.xz" >"$tmpdir/list.txt"
validator_assert_contains "$tmpdir/list.txt" 'payload.txt'

bsdtar -xf "$tmpdir/a.tar.xz" -C "$tmpdir/out"
diff "$tmpdir/in/payload.txt" "$tmpdir/out/payload.txt"

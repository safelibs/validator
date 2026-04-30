#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-bsdcat-frame-decompress
# @title: bsdcat reads zstd-compressed tar
# @description: Compresses a tar with bsdtar --zstd then streams it through bsdcat and verifies a known member payload appears in the output.
# @timeout: 180
# @tags: usage, archive, zstd, bsdcat
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in"
printf 'bsdcat zstd marker payload\n' >"$tmpdir/in/marker.txt"

bsdtar --zstd -cf "$tmpdir/a.tar.zst" -C "$tmpdir/in" marker.txt
validator_require_file "$tmpdir/a.tar.zst"

magic=$(od -An -N4 -tx1 "$tmpdir/a.tar.zst" | tr -d ' \n')
test "$magic" = "28b52ffd"

bsdcat "$tmpdir/a.tar.zst" >"$tmpdir/out.bin"
validator_assert_contains "$tmpdir/out.bin" 'bsdcat zstd marker payload'

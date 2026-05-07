#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-r14-decompress-short-flag-roundtrip
# @title: xz -d short flag and --decompress long flag both round-trip the same archive
# @description: Compresses a payload to .xz, decompresses one copy with "xz -d -c" and another with "xz --decompress -c", then asserts both decoded outputs match the source sha256 byte-for-byte, pinning that the short and long forms are equivalent.
# @timeout: 60
# @tags: usage, xz, decompress, flags
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'short-vs-long decompress flag payload alpha\n' >"$tmpdir/in.txt"
src_sha=$(sha256sum "$tmpdir/in.txt" | awk '{print $1}')

xz -c "$tmpdir/in.txt" >"$tmpdir/out.xz"

xz -d -c "$tmpdir/out.xz" >"$tmpdir/d_short.txt"
xz --decompress -c "$tmpdir/out.xz" >"$tmpdir/d_long.txt"

test "$src_sha" = "$(sha256sum "$tmpdir/d_short.txt" | awk '{print $1}')"
test "$src_sha" = "$(sha256sum "$tmpdir/d_long.txt" | awk '{print $1}')"

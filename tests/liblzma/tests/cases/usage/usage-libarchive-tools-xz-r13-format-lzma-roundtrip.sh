#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-r13-format-lzma-roundtrip
# @title: xz -F lzma legacy stream encodes and decodes via xz round-trip
# @description: Encodes a payload with "xz -F lzma -c" to produce a legacy .lzma stream, verifies the leading 0x5d byte marker, then decodes it back via "xz -F lzma -d -c" and asserts the recovered bytes match the source via sha256.
# @timeout: 60
# @tags: usage, xz, lzma, legacy
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'legacy-lzma payload contents alpha beta gamma\n' >"$tmpdir/in.txt"
src_sha=$(sha256sum "$tmpdir/in.txt" | awk '{print $1}')

xz -F lzma -c "$tmpdir/in.txt" >"$tmpdir/out.lzma"

magic_byte=$(head -c 1 "$tmpdir/out.lzma" | od -An -tx1 | tr -d ' \n')
test "$magic_byte" = "5d"

xz -F lzma -d -c "$tmpdir/out.lzma" >"$tmpdir/decoded.txt"
test "$src_sha" = "$(sha256sum "$tmpdir/decoded.txt" | awk '{print $1}')"

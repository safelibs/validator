#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-r12-lzcat-decodes-legacy
# @title: lzcat decodes a legacy .lzma stream
# @description: Encodes a payload with "xz -F lzma -c" to produce a legacy LZMA stream and verifies "lzcat" decodes that file to byte-equal stdout, exercising the lzma alias interface.
# @timeout: 60
# @tags: usage, lzma, lzcat, legacy
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'lzcat legacy payload alpha beta\n' >"$tmpdir/in.txt"
src_sha=$(sha256sum "$tmpdir/in.txt" | awk '{print $1}')

xz -F lzma -c "$tmpdir/in.txt" >"$tmpdir/out.lzma"

magic_byte=$(head -c 1 "$tmpdir/out.lzma" | od -An -tx1 | tr -d ' \n')
test "$magic_byte" = "5d"

lzcat "$tmpdir/out.lzma" >"$tmpdir/decoded.txt"
out_sha=$(sha256sum "$tmpdir/decoded.txt" | awk '{print $1}')
test "$src_sha" = "$out_sha"

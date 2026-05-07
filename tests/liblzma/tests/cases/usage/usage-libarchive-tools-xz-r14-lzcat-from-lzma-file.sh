#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-r14-lzcat-from-lzma-file
# @title: lzcat decodes a .lzma legacy stream produced by lzma -c
# @description: Compresses a payload with "lzma -c" to a .lzma legacy stream, then runs "lzcat" on the resulting file and asserts stdout matches the source sha256 — exercising lzcat against a .lzma file (distinct from r12's lzcat-decodes-legacy which uses an xz-format-lzma archive).
# @timeout: 60
# @tags: usage, lzcat, lzma
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 -c '
import sys
for i in range(150):
    sys.stdout.write("lzcat lzma row %03d\n" % i)
' >"$tmpdir/in.txt"
src_sha=$(sha256sum "$tmpdir/in.txt" | awk '{print $1}')

lzma -c "$tmpdir/in.txt" >"$tmpdir/out.lzma"

magic_byte=$(head -c 1 "$tmpdir/out.lzma" | od -An -tx1 | tr -d ' \n')
test "$magic_byte" = "5d"

lzcat "$tmpdir/out.lzma" >"$tmpdir/decoded.txt"
test "$src_sha" = "$(sha256sum "$tmpdir/decoded.txt" | awk '{print $1}')"

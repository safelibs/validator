#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-r16-xzdec-decompresses-single-stream
# @title: xzdec decompresses a single-stream xz file byte-for-byte
# @description: Compresses a payload with xz -c, decompresses with xzdec (the minimal liblzma-only decoder), and asserts the decompressed stdout matches the original input byte-for-byte via sha256sum.
# @timeout: 60
# @tags: usage, xzdec, decompress, single-stream
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'r16 xzdec payload alpha beta gamma 0123456789\n' >"$tmpdir/in.txt"
expected=$(sha256sum "$tmpdir/in.txt" | awk '{print $1}')

xz -c "$tmpdir/in.txt" >"$tmpdir/in.txt.xz"
xzdec "$tmpdir/in.txt.xz" >"$tmpdir/out.txt"

actual=$(sha256sum "$tmpdir/out.txt" | awk '{print $1}')
test "$actual" = "$expected"

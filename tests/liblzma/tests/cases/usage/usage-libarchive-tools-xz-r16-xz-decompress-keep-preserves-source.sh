#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-r16-xz-decompress-keep-preserves-source
# @title: xz --decompress --keep preserves the .xz input alongside the new file
# @description: Compresses a payload with xz -k, then runs xz --decompress --keep on the .xz file and asserts BOTH the .xz and the decompressed output exist afterwards with matching content via sha256sum on the decoded copy.
# @timeout: 60
# @tags: usage, xz, decompress, keep
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'r16 keep-decompress payload alpha beta\n' >"$tmpdir/in.txt"
expected=$(sha256sum "$tmpdir/in.txt" | awk '{print $1}')

xz -k "$tmpdir/in.txt"
test -f "$tmpdir/in.txt"
test -f "$tmpdir/in.txt.xz"

# Remove the original and decompress with --keep so both decoded and .xz remain.
rm "$tmpdir/in.txt"
xz --decompress --keep "$tmpdir/in.txt.xz"

test -f "$tmpdir/in.txt.xz"
test -f "$tmpdir/in.txt"

actual=$(sha256sum "$tmpdir/in.txt" | awk '{print $1}')
test "$actual" = "$expected"

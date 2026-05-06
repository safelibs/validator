#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-r10-suffix-custom
# @title: xz --suffix custom output extension
# @description: Encodes a payload with xz --suffix=.xzfoo to override the default .xz extension, then decodes it back via xz --suffix=.xzfoo and verifies the bytes match.
# @timeout: 120
# @tags: usage, xz, suffix
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'custom-suffix payload alpha beta\n' >"$tmpdir/data.txt"
src_sha=$(sha256sum "$tmpdir/data.txt" | awk '{print $1}')

xz --suffix=.xzfoo --keep "$tmpdir/data.txt"

[[ -f "$tmpdir/data.txt.xzfoo" ]]
[[ ! -f "$tmpdir/data.txt.xz" ]]

magic_hex=$(head -c 6 "$tmpdir/data.txt.xzfoo" | od -An -tx1 | tr -d ' \n')
test "$magic_hex" = "fd377a585a00"

rm -f "$tmpdir/data.txt"
xz --suffix=.xzfoo --decompress "$tmpdir/data.txt.xzfoo"

[[ -f "$tmpdir/data.txt" ]]
out_sha=$(sha256sum "$tmpdir/data.txt" | awk '{print $1}')
test "$src_sha" = "$out_sha"

#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-r13-suffix-foo-roundtrip
# @title: xz --suffix=.foo writes and decodes with the custom suffix
# @description: Compresses a payload using xz --suffix=.foo --keep, verifies the output filename ends with .foo (not .xz), checks the .xz container magic bytes, and decompresses with the same --suffix to recover the source bytes via sha256.
# @timeout: 60
# @tags: usage, xz, suffix
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'suffix-foo payload contents\nsecond line\n' >"$tmpdir/data.txt"
src_sha=$(sha256sum "$tmpdir/data.txt" | awk '{print $1}')

xz --suffix=.foo --keep "$tmpdir/data.txt"

[[ -f "$tmpdir/data.txt.foo" ]]
[[ ! -f "$tmpdir/data.txt.xz" ]]

magic_hex=$(head -c 6 "$tmpdir/data.txt.foo" | od -An -tx1 | tr -d ' \n')
test "$magic_hex" = "fd377a585a00"

rm "$tmpdir/data.txt"
xz --suffix=.foo --decompress "$tmpdir/data.txt.foo"
[[ -f "$tmpdir/data.txt" ]]
out_sha=$(sha256sum "$tmpdir/data.txt" | awk '{print $1}')
test "$src_sha" = "$out_sha"

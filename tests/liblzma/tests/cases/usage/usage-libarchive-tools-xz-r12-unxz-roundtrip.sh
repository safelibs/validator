#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-r12-unxz-roundtrip
# @title: unxz round-trip restores original payload and removes the .xz file
# @description: Compresses a payload via xz, then runs "unxz" on the .xz file (no --keep) and verifies the .xz file is removed, the decompressed file is restored at the original path, and its bytes match the source.
# @timeout: 60
# @tags: usage, xz, unxz
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'unxz roundtrip payload alpha beta gamma\n' >"$tmpdir/data.txt"
src_sha=$(sha256sum "$tmpdir/data.txt" | awk '{print $1}')

xz "$tmpdir/data.txt"
test ! -f "$tmpdir/data.txt"
test -f "$tmpdir/data.txt.xz"

unxz "$tmpdir/data.txt.xz"
test -f "$tmpdir/data.txt"
test ! -f "$tmpdir/data.txt.xz"

out_sha=$(sha256sum "$tmpdir/data.txt" | awk '{print $1}')
test "$src_sha" = "$out_sha"

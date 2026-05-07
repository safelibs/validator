#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-r12-keep-source-after-compress
# @title: xz -k preserves the source file alongside the .xz output
# @description: Runs "xz -k" on a regular file and verifies both the original file and the new .xz sibling are present afterward, with the .xz file decompressing back to the source's bytes.
# @timeout: 60
# @tags: usage, xz, keep
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'keep-source xz payload alpha beta gamma\n' >"$tmpdir/data.txt"
src_sha=$(sha256sum "$tmpdir/data.txt" | awk '{print $1}')

xz -k "$tmpdir/data.txt"

# Both source and compressed sibling exist.
test -f "$tmpdir/data.txt"
test -f "$tmpdir/data.txt.xz"

# Source unchanged.
preserved_sha=$(sha256sum "$tmpdir/data.txt" | awk '{print $1}')
test "$src_sha" = "$preserved_sha"

# .xz decompresses back to identical content.
xz -dc "$tmpdir/data.txt.xz" >"$tmpdir/decoded.txt"
out_sha=$(sha256sum "$tmpdir/decoded.txt" | awk '{print $1}')
test "$src_sha" = "$out_sha"

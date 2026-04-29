#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-double-strip-components
# @title: libarchive-tools zstd double strip components
# @description: Extracts a deeply nested member from a zstd-compressed tar with multiple stripped path components.
# @timeout: 180
# @tags: usage, archive, zstd
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-libarchive-tools-zstd-double-strip-components"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in/root/dir/sub" "$tmpdir/out"
printf 'gamma\n' >"$tmpdir/in/root/dir/sub/gamma.txt"
bsdtar --zstd -cf "$tmpdir/a.tar.zstd" -C "$tmpdir/in" 'root/dir/sub/gamma.txt'
bsdtar --strip-components 3 -xf "$tmpdir/a.tar.zstd" -C "$tmpdir/out"
validator_assert_contains "$tmpdir/out/gamma.txt" 'gamma'

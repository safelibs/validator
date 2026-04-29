#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-double-strip-components
# @title: libarchive-tools xz double strip components
# @description: Extracts a deeply nested member from an xz-compressed tar with multiple stripped path components.
# @timeout: 180
# @tags: usage, archive, xz
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-libarchive-tools-xz-double-strip-components"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in/root/dir/sub" "$tmpdir/out"
printf 'gamma\n' >"$tmpdir/in/root/dir/sub/gamma.txt"
bsdtar -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/in" 'root/dir/sub/gamma.txt'
bsdtar --strip-components 3 -xf "$tmpdir/a.tar.xz" -C "$tmpdir/out"
validator_assert_contains "$tmpdir/out/gamma.txt" 'gamma'

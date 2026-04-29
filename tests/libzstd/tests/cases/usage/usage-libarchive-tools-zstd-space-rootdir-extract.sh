#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-space-rootdir-extract
# @title: libarchive-tools zstd spaced root extract
# @description: Archives and extracts a top-level directory containing spaces in a zstd-compressed tar.
# @timeout: 180
# @tags: usage, archive, zstd
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-libarchive-tools-zstd-space-rootdir-extract"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in/space root" "$tmpdir/out"
printf 'inner\n' >"$tmpdir/in/space root/inner.txt"
bsdtar --zstd -cf "$tmpdir/a.tar.zstd" -C "$tmpdir/in" 'space root'
bsdtar -xf "$tmpdir/a.tar.zstd" -C "$tmpdir/out"
validator_assert_contains "$tmpdir/out/space root/inner.txt" 'inner'

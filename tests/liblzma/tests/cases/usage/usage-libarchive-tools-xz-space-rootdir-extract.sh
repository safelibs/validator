#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-space-rootdir-extract
# @title: libarchive-tools xz spaced root extract
# @description: Archives and extracts a top-level directory containing spaces in an xz-compressed tar.
# @timeout: 180
# @tags: usage, archive, xz
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-libarchive-tools-xz-space-rootdir-extract"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in/space root" "$tmpdir/out"
printf 'inner\n' >"$tmpdir/in/space root/inner.txt"
bsdtar -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/in" 'space root'
bsdtar -xf "$tmpdir/a.tar.xz" -C "$tmpdir/out"
validator_assert_contains "$tmpdir/out/space root/inner.txt" 'inner'

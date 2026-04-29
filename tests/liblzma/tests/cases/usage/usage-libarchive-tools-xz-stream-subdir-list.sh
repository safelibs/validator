#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-stream-subdir-list
# @title: libarchive-tools xz stream subdir list
# @description: Streams an xz-compressed tar through bsdtar and verifies a nested subdirectory member appears in the listing.
# @timeout: 180
# @tags: usage, archive, xz
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-libarchive-tools-xz-stream-subdir-list"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in/root/dir/sub"
printf 'gamma\n' >"$tmpdir/in/root/dir/sub/gamma.txt"
bsdtar -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/in" root/dir/sub
cat "$tmpdir/a.tar.xz" | bsdtar -tf - | tee "$tmpdir/list"
validator_assert_contains "$tmpdir/list" 'root/dir/sub/gamma.txt'

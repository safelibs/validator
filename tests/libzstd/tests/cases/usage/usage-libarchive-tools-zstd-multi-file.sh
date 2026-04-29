#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-multi-file
# @title: libarchive-tools zstd multi-file
# @description: Creates a zstd-compressed tar archive containing multiple files and checks the listing.
# @timeout: 180
# @tags: usage, archive, zstd
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-libarchive-tools-zstd-multi-file"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

make_tree() {
  mkdir -p "$tmpdir/in/dir/sub" "$tmpdir/out"
  printf 'alpha payload\n' >"$tmpdir/in/alpha.txt"
  printf 'beta payload\n' >"$tmpdir/in/dir/beta.txt"
  printf 'gamma payload\n' >"$tmpdir/in/dir/sub/gamma.txt"
  printf 'space payload\n' >"$tmpdir/in/space name.txt"
}

make_tree
bsdtar --zstd -cf "$tmpdir/a.tar.zstd" -C "$tmpdir/in" alpha.txt dir/beta.txt
bsdtar -tf "$tmpdir/a.tar.zstd" | tee "$tmpdir/list"
validator_assert_contains "$tmpdir/list" 'alpha.txt'
validator_assert_contains "$tmpdir/list" 'dir/beta.txt'

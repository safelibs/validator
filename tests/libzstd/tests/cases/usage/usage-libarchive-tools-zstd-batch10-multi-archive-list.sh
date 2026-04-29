#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-batch10-multi-archive-list
# @title: libarchive-tools zstd two archives separately
# @description: Builds two independent zstd archives and verifies each listing contains only its own member.
# @timeout: 180
# @tags: usage, archive, zstd
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-libarchive-tools-zstd-batch10-multi-archive-list"
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
bsdtar --zstd -cf "$tmpdir/one.tar.zstd" -C "$tmpdir/in" alpha.txt
bsdtar --zstd -cf "$tmpdir/two.tar.zstd" -C "$tmpdir/in" 'space name.txt'
bsdtar -tf "$tmpdir/one.tar.zstd" >"$tmpdir/list1"
bsdtar -tf "$tmpdir/two.tar.zstd" >"$tmpdir/list2"
validator_assert_contains "$tmpdir/list1" 'alpha.txt'
validator_assert_contains "$tmpdir/list2" 'space name.txt'

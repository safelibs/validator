#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-batch10-mixed-format-list
# @title: libarchive-tools zstd mixed listing exact count
# @description: Adds three members including a spaced filename to a zstd tar and verifies the listing reports exactly three entries.
# @timeout: 180
# @tags: usage, archive, zstd
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-libarchive-tools-zstd-batch10-mixed-format-list"
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
bsdtar --zstd -cf "$tmpdir/a.tar.zstd" -C "$tmpdir/in" alpha.txt dir/beta.txt 'space name.txt'
bsdtar -tf "$tmpdir/a.tar.zstd" >"$tmpdir/list"
test "$(wc -l <"$tmpdir/list")" -eq 3
validator_assert_contains "$tmpdir/list" 'alpha.txt'
validator_assert_contains "$tmpdir/list" 'dir/beta.txt'
validator_assert_contains "$tmpdir/list" 'space name.txt'

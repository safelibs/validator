#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-space-dir-list
# @title: libarchive tools zstd space directory list
# @description: Exercises libarchive tools zstd space directory list through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-libarchive-tools-zstd-space-dir-list"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

make_tree() {
  mkdir -p "$tmpdir/in/dir/sub" "$tmpdir/out"
  printf 'alpha payload\n' >"$tmpdir/in/alpha.txt"
  printf 'beta payload\n' >"$tmpdir/in/dir/beta.txt"
  printf 'gamma payload\n' >"$tmpdir/in/dir/sub/gamma.txt"
  printf 'space payload\n' >"$tmpdir/in/space name.txt"
}

mkdir -p "$tmpdir/in/space dir"
printf 'space dir payload\n' >"$tmpdir/in/space dir/item.txt"
bsdtar --zstd -cf "$tmpdir/a.tar.zstd" -C "$tmpdir/in" 'space dir'
bsdtar -tf "$tmpdir/a.tar.zstd" >"$tmpdir/list"
validator_assert_contains "$tmpdir/list" 'space dir/item.txt'

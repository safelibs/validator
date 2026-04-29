#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-space-dir
# @title: libarchive-tools xz spaced directory
# @description: Archives a directory with spaces under xz compression and verifies the nested file extracts correctly.
# @timeout: 180
# @tags: usage, archive, xz
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-libarchive-tools-xz-space-dir"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

make_tree() {
  mkdir -p "$tmpdir/in/dir/sub" "$tmpdir/out"
  printf 'alpha payload\n' >"$tmpdir/in/alpha.txt"
  printf 'beta payload\n' >"$tmpdir/in/dir/beta.txt"
  printf 'gamma payload\n' >"$tmpdir/in/dir/sub/gamma.txt"
  printf 'space payload\n' >"$tmpdir/in/space name.txt"
}

mkdir -p "$tmpdir/in/space dir" "$tmpdir/out"
printf 'space dir payload\n' >"$tmpdir/in/space dir/item.txt"
bsdtar -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/in" 'space dir'
bsdtar -xf "$tmpdir/a.tar.xz" -C "$tmpdir/out"
validator_assert_contains "$tmpdir/out/space dir/item.txt" 'space dir payload'

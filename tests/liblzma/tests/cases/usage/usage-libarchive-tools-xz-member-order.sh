#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-member-order
# @title: libarchive-tools xz member order
# @description: Creates an xz-compressed archive with a specific member order and verifies bsdtar list mode preserves that order.
# @timeout: 180
# @tags: usage, archive, xz
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-libarchive-tools-xz-member-order"
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
bsdtar -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/in" dir/beta.txt alpha.txt
bsdtar -tf "$tmpdir/a.tar.xz" >"$tmpdir/list"
first=$(sed -n '1p' "$tmpdir/list")
second=$(sed -n '2p' "$tmpdir/list")
test "$first" = 'dir/beta.txt'
test "$second" = 'alpha.txt'

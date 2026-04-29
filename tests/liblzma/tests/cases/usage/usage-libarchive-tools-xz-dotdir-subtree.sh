#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-dotdir-subtree
# @title: libarchive-tools xz dotdir subtree
# @description: Archives a hidden subtree under xz compression and verifies the nested member path appears in the archive listing.
# @timeout: 180
# @tags: usage, archive, xz
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-libarchive-tools-xz-dotdir-subtree"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

make_tree() {
  mkdir -p "$tmpdir/in/dir/sub" "$tmpdir/out"
  printf 'alpha payload\n' >"$tmpdir/in/alpha.txt"
  printf 'beta payload\n' >"$tmpdir/in/dir/beta.txt"
  printf 'gamma payload\n' >"$tmpdir/in/dir/sub/gamma.txt"
  printf 'space payload\n' >"$tmpdir/in/space name.txt"
}

mkdir -p "$tmpdir/in/.cache/sub"
printf 'cache payload\n' >"$tmpdir/in/.cache/sub/value.txt"
bsdtar -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/in" .cache/sub
bsdtar -tf "$tmpdir/a.tar.xz" | tee "$tmpdir/list"
validator_assert_contains "$tmpdir/list" '.cache/sub/value.txt'

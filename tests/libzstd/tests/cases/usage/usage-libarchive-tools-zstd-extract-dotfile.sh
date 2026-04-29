#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-extract-dotfile
# @title: libarchive-tools zstd extract dotfile
# @description: Extracts only a hidden file from a zstd-compressed archive and verifies nonselected members are left out.
# @timeout: 180
# @tags: usage, archive, zstd
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-libarchive-tools-zstd-extract-dotfile"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

make_tree() {
  mkdir -p "$tmpdir/in/dir/sub" "$tmpdir/out"
  printf 'alpha payload\n' >"$tmpdir/in/alpha.txt"
  printf 'beta payload\n' >"$tmpdir/in/dir/beta.txt"
  printf 'gamma payload\n' >"$tmpdir/in/dir/sub/gamma.txt"
  printf 'space payload\n' >"$tmpdir/in/space name.txt"
}

mkdir -p "$tmpdir/in" "$tmpdir/out"
printf 'hidden payload\n' >"$tmpdir/in/.hidden"
printf 'visible payload\n' >"$tmpdir/in/visible.txt"
bsdtar --zstd -cf "$tmpdir/a.tar.zstd" -C "$tmpdir/in" .hidden visible.txt
bsdtar -xf "$tmpdir/a.tar.zstd" -C "$tmpdir/out" .hidden
validator_assert_contains "$tmpdir/out/.hidden" 'hidden payload'
test ! -e "$tmpdir/out/visible.txt"

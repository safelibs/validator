#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-symlink-listing
# @title: libarchive-tools xz symlink listing
# @description: Lists an xz-compressed archive containing a symbolic link and verifies the link member appears in verbose output.
# @timeout: 180
# @tags: usage, archive, xz
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-libarchive-tools-xz-symlink-listing"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

make_tree() {
  mkdir -p "$tmpdir/in/dir/sub" "$tmpdir/out"
  printf 'alpha payload\n' >"$tmpdir/in/alpha.txt"
  printf 'beta payload\n' >"$tmpdir/in/dir/beta.txt"
  printf 'gamma payload\n' >"$tmpdir/in/dir/sub/gamma.txt"
  printf 'space payload\n' >"$tmpdir/in/space name.txt"
}

mkdir -p "$tmpdir/in"
printf 'symlink payload\n' >"$tmpdir/in/original.txt"
ln -s original.txt "$tmpdir/in/original.link"
bsdtar -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/in" original.txt original.link
bsdtar -tvf "$tmpdir/a.tar.xz" | tee "$tmpdir/list"
validator_assert_contains "$tmpdir/list" 'original.link'

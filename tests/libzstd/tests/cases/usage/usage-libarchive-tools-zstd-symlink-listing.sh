#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-symlink-listing
# @title: libarchive-tools zstd symlink listing
# @description: Lists a zstd-compressed archive containing a symbolic link and verifies the link member appears in verbose output.
# @timeout: 180
# @tags: usage, archive, zstd
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-libarchive-tools-zstd-symlink-listing"
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
bsdtar --zstd -cf "$tmpdir/a.tar.zstd" -C "$tmpdir/in" original.txt original.link
bsdtar -tvf "$tmpdir/a.tar.zstd" | tee "$tmpdir/list"
validator_assert_contains "$tmpdir/list" 'original.link'

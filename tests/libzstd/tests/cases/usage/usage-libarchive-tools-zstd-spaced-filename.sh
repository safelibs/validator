#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-spaced-filename
# @title: libarchive-tools zstd spaced filename
# @description: Archives and extracts a filename containing a space through zstd compression.
# @timeout: 180
# @tags: usage, archive, zstd
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-libarchive-tools-zstd-spaced-filename"
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
bsdtar --zstd -cf "$tmpdir/a.tar.zstd" -C "$tmpdir/in" 'space name.txt'
bsdtar -xf "$tmpdir/a.tar.zstd" -C "$tmpdir/out"
validator_assert_contains "$tmpdir/out/space name.txt" 'space payload'

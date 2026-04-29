#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-topdir-strip-one
# @title: libarchive-tools zstd topdir strip one
# @description: Archives a top-level directory under zstd compression and extracts it with one stripped path component.
# @timeout: 180
# @tags: usage, archive, zstd
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-libarchive-tools-zstd-topdir-strip-one"
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
bsdtar --zstd -cf "$tmpdir/a.tar.zstd" -C "$tmpdir" in
bsdtar --strip-components 1 -xf "$tmpdir/a.tar.zstd" -C "$tmpdir/out"
validator_assert_contains "$tmpdir/out/alpha.txt" 'alpha payload'
validator_assert_contains "$tmpdir/out/dir/beta.txt" 'beta payload'

#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-dotdir-entry
# @title: libarchive-tools zstd dotdir entry
# @description: Archives a hidden directory tree with zstd compression and verifies hidden nested files extract correctly.
# @timeout: 180
# @tags: usage, archive, zstd
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-libarchive-tools-zstd-dotdir-entry"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

make_tree() {
  mkdir -p "$tmpdir/in/dir/sub" "$tmpdir/out"
  printf 'alpha payload\n' >"$tmpdir/in/alpha.txt"
  printf 'beta payload\n' >"$tmpdir/in/dir/beta.txt"
  printf 'gamma payload\n' >"$tmpdir/in/dir/sub/gamma.txt"
  printf 'space payload\n' >"$tmpdir/in/space name.txt"
}

mkdir -p "$tmpdir/in/.config/sub" "$tmpdir/out"
printf 'dotdir payload\n' >"$tmpdir/in/.config/sub/value.txt"
bsdtar --zstd -cf "$tmpdir/a.tar.zstd" -C "$tmpdir/in" .config
bsdtar -xf "$tmpdir/a.tar.zstd" -C "$tmpdir/out"
validator_assert_contains "$tmpdir/out/.config/sub/value.txt" 'dotdir payload'

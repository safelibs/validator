#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-batch11-transform-name
# @title: bsdtar zstd transform name
# @description: Uses bsdtar path substitution while creating a zstd-compressed tar archive.
# @timeout: 180
# @tags: usage, archive, zstd
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-libarchive-tools-zstd-batch11-transform-name"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

make_archive() {
  mkdir -p "$tmpdir/src/top/nested" "$tmpdir/src/space dir"
  printf 'alpha payload\n' >"$tmpdir/src/top/alpha.txt"
  printf 'beta payload\n' >"$tmpdir/src/top/nested/beta.txt"
  printf 'space payload\n' >"$tmpdir/src/space dir/file name.txt"
  printf 'skip payload\n' >"$tmpdir/src/top/skip.tmp"
  bsdtar -acf "$tmpdir/archive.tar.zst" -C "$tmpdir/src" .
}

mkdir -p "$tmpdir/src"
printf 'rename\n' >"$tmpdir/src/oldname.txt"
bsdtar -acf "$tmpdir/archive.tar.zst" -s /oldname/newname/ -C "$tmpdir/src" oldname.txt
bsdtar -tf "$tmpdir/archive.tar.zst" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'newname.txt'

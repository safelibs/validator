#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-batch11-null-filelist
# @title: bsdtar xz null file list
# @description: Creates an xz archive from a null-delimited file list with bsdtar.
# @timeout: 180
# @tags: usage, archive, xz
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-libarchive-tools-xz-batch11-null-filelist"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

make_archive() {
  mkdir -p "$tmpdir/src/top/nested" "$tmpdir/src/space dir"
  printf 'alpha payload\n' >"$tmpdir/src/top/alpha.txt"
  printf 'beta payload\n' >"$tmpdir/src/top/nested/beta.txt"
  printf 'space payload\n' >"$tmpdir/src/space dir/file name.txt"
  printf 'skip payload\n' >"$tmpdir/src/top/skip.tmp"
  bsdtar -acf "$tmpdir/archive.tar.xz" -C "$tmpdir/src" .
}

mkdir -p "$tmpdir/src"
printf 'alpha\n' >"$tmpdir/src/alpha.txt"
printf 'beta\n' >"$tmpdir/src/beta.txt"
printf 'alpha.txt\0beta.txt\0' >"$tmpdir/list0"
bsdtar --null -acf "$tmpdir/archive.tar.xz" -C "$tmpdir/src" -T "$tmpdir/list0"
bsdtar -tf "$tmpdir/archive.tar.xz" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'alpha.txt'
validator_assert_contains "$tmpdir/out" 'beta.txt'

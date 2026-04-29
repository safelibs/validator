#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-batch11-filelist-create
# @title: bsdtar xz file list create
# @description: Creates an xz archive from a newline-delimited file list and verifies the selected members.
# @timeout: 180
# @tags: usage, archive, xz
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-libarchive-tools-xz-batch11-filelist-create"
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
printf 'one\n' >"$tmpdir/src/one.txt"
printf 'two\n' >"$tmpdir/src/two.txt"
printf 'one.txt\ntwo.txt\n' >"$tmpdir/list"
bsdtar -acf "$tmpdir/archive.tar.xz" -C "$tmpdir/src" -T "$tmpdir/list"
bsdtar -tf "$tmpdir/archive.tar.xz" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'one.txt'
validator_assert_contains "$tmpdir/out" 'two.txt'

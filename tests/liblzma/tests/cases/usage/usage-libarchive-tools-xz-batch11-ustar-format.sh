#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-batch11-ustar-format
# @title: bsdtar xz ustar format
# @description: Creates an xz-compressed archive using the ustar tar format option.
# @timeout: 180
# @tags: usage, archive, xz
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-libarchive-tools-xz-batch11-ustar-format"
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
printf 'ustar\n' >"$tmpdir/src/ustar.txt"
bsdtar --format=ustar -acf "$tmpdir/archive.tar.xz" -C "$tmpdir/src" ustar.txt
bsdtar -tf "$tmpdir/archive.tar.xz" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'ustar.txt'

#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-batch11-owner-labels
# @title: bsdtar xz owner labels
# @description: Writes custom owner labels into an xz-compressed tar archive and verifies verbose listing output.
# @timeout: 180
# @tags: usage, archive, xz
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-libarchive-tools-xz-batch11-owner-labels"
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
printf 'owner\n' >"$tmpdir/src/owned.txt"
bsdtar --uid 123 --gid 456 --uname validator --gname validators -acf "$tmpdir/archive.tar.xz" -C "$tmpdir/src" owned.txt
bsdtar -tvf "$tmpdir/archive.tar.xz" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'validator'
validator_assert_contains "$tmpdir/out" 'validators'

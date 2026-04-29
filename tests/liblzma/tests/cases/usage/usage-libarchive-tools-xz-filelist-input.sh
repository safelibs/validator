#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-filelist-input
# @title: libarchive-tools xz file list input
# @description: Creates an xz-compressed tar archive from a file list and verifies the archived members.
# @timeout: 180
# @tags: usage, archive, xz
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-libarchive-tools-xz-filelist-input"
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
printf 'alpha.txt\ndir/beta.txt\n' >"$tmpdir/files.txt"
bsdtar -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/in" -T "$tmpdir/files.txt"
bsdtar -tf "$tmpdir/a.tar.xz" | tee "$tmpdir/list"
validator_assert_contains "$tmpdir/list" 'alpha.txt'
validator_assert_contains "$tmpdir/list" 'dir/beta.txt'

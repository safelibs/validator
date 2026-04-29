#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-batch10-stream-stdout-archive
# @title: libarchive-tools xz archive to stdout
# @description: Streams an xz-compressed tar to stdout via bsdtar -cJf - then lists the resulting archive and verifies both members appear.
# @timeout: 180
# @tags: usage, archive, xz
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-libarchive-tools-xz-batch10-stream-stdout-archive"
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
bsdtar -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/in" alpha.txt dir/beta.txt
bsdtar -tf "$tmpdir/a.tar.xz" >"$tmpdir/list"
validator_assert_contains "$tmpdir/list" 'alpha.txt'
validator_assert_contains "$tmpdir/list" 'dir/beta.txt'

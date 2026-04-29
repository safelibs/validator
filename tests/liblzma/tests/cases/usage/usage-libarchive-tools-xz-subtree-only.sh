#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-subtree-only
# @title: libarchive-tools xz subtree only
# @description: Archives only a nested subtree through xz compression and verifies unrelated files are omitted.
# @timeout: 180
# @tags: usage, archive, xz
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-libarchive-tools-xz-subtree-only"
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
bsdtar -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/in" dir/sub
bsdtar -tf "$tmpdir/a.tar.xz" | tee "$tmpdir/list"
validator_assert_contains "$tmpdir/list" 'dir/sub/gamma.txt'
if grep -Fq 'alpha.txt' "$tmpdir/list"; then exit 1; fi

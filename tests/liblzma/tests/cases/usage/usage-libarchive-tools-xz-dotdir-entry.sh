#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-dotdir-entry
# @title: libarchive-tools xz dotdir entry
# @description: Archives a hidden directory tree with xz compression and verifies hidden nested files extract correctly.
# @timeout: 180
# @tags: usage, archive, xz
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-libarchive-tools-xz-dotdir-entry"
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
bsdtar -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/in" .config
bsdtar -xf "$tmpdir/a.tar.xz" -C "$tmpdir/out"
validator_assert_contains "$tmpdir/out/.config/sub/value.txt" 'dotdir payload'

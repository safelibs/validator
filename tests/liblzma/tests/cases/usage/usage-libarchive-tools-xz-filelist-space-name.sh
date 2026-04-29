#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-filelist-space-name
# @title: libarchive tools xz file list spaced name
# @description: Exercises libarchive tools xz file list spaced name through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-libarchive-tools-xz-filelist-space-name"
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
printf 'space name.txt\n' >"$tmpdir/files.txt"
bsdtar -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/in" -T "$tmpdir/files.txt"
bsdtar -xf "$tmpdir/a.tar.xz" -C "$tmpdir/out"
validator_assert_contains "$tmpdir/out/space name.txt" 'space payload'

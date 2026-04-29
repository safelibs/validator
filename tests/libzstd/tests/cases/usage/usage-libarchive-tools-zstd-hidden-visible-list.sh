#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-hidden-visible-list
# @title: libarchive tools zstd hidden visible list
# @description: Exercises libarchive tools zstd hidden visible list through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-libarchive-tools-zstd-hidden-visible-list"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

make_tree() {
  mkdir -p "$tmpdir/in/dir/sub" "$tmpdir/out"
  printf 'alpha payload\n' >"$tmpdir/in/alpha.txt"
  printf 'beta payload\n' >"$tmpdir/in/dir/beta.txt"
  printf 'gamma payload\n' >"$tmpdir/in/dir/sub/gamma.txt"
  printf 'space payload\n' >"$tmpdir/in/space name.txt"
}

mkdir -p "$tmpdir/in"
printf 'hidden payload\n' >"$tmpdir/in/.hidden"
printf 'visible payload\n' >"$tmpdir/in/visible.txt"
bsdtar --zstd -cf "$tmpdir/a.tar.zstd" -C "$tmpdir/in" .hidden visible.txt
bsdtar -tf "$tmpdir/a.tar.zstd" >"$tmpdir/list"
validator_assert_contains "$tmpdir/list" '.hidden'
validator_assert_contains "$tmpdir/list" 'visible.txt'

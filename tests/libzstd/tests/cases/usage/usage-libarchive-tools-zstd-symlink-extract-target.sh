#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-symlink-extract-target
# @title: libarchive tools zstd symlink extract target
# @description: Exercises libarchive tools zstd symlink extract target through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-libarchive-tools-zstd-symlink-extract-target"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

make_tree() {
  mkdir -p "$tmpdir/in/dir/sub" "$tmpdir/out"
  printf 'alpha payload\n' >"$tmpdir/in/alpha.txt"
  printf 'beta payload\n' >"$tmpdir/in/dir/beta.txt"
  printf 'gamma payload\n' >"$tmpdir/in/dir/sub/gamma.txt"
  printf 'space payload\n' >"$tmpdir/in/space name.txt"
}

mkdir -p "$tmpdir/in" "$tmpdir/out"
printf 'symlink payload\n' >"$tmpdir/in/original.txt"
ln -s original.txt "$tmpdir/in/original.link"
bsdtar --zstd -cf "$tmpdir/a.tar.zstd" -C "$tmpdir/in" original.txt original.link
bsdtar -xf "$tmpdir/a.tar.zstd" -C "$tmpdir/out"
test "$(readlink "$tmpdir/out/original.link")" = 'original.txt'

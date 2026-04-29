#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-hardlink-extract-compare
# @title: libarchive tools xz hardlink extract compare
# @description: Exercises libarchive tools xz hardlink extract compare through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-libarchive-tools-xz-hardlink-extract-compare"
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
printf 'link payload\n' >"$tmpdir/in/original.txt"
ln "$tmpdir/in/original.txt" "$tmpdir/in/original.hard"
bsdtar -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/in" original.txt original.hard
bsdtar -xf "$tmpdir/a.tar.xz" -C "$tmpdir/out"
cmp -s "$tmpdir/out/original.txt" "$tmpdir/out/original.hard"

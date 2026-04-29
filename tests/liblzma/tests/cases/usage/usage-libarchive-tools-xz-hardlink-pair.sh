#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-hardlink-pair
# @title: libarchive-tools xz hardlink pair
# @description: Archives and extracts hardlinked files through xz compression and checks their content matches.
# @timeout: 180
# @tags: usage, archive, xz
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-libarchive-tools-xz-hardlink-pair"
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
ln "$tmpdir/in/original.txt" "$tmpdir/in/original.link"
bsdtar -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/in" original.txt original.link
bsdtar -xf "$tmpdir/a.tar.xz" -C "$tmpdir/out"
cmp -s "$tmpdir/out/original.txt" "$tmpdir/out/original.link"

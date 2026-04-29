#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-multi-empty-files
# @title: libarchive-tools zstd multiple empty files
# @description: Archives multiple empty files under zstd compression and verifies both extracted files remain zero bytes.
# @timeout: 180
# @tags: usage, archive, zstd
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-libarchive-tools-zstd-multi-empty-files"
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
: >"$tmpdir/in/one.txt"
: >"$tmpdir/in/two.txt"
bsdtar --zstd -cf "$tmpdir/a.tar.zstd" -C "$tmpdir/in" one.txt two.txt
bsdtar -xf "$tmpdir/a.tar.zstd" -C "$tmpdir/out"
test "$(wc -c <"$tmpdir/out/one.txt")" -eq 0
test "$(wc -c <"$tmpdir/out/two.txt")" -eq 0

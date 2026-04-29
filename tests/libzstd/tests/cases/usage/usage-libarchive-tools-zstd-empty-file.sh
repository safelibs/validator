#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-empty-file
# @title: libarchive-tools zstd empty file
# @description: Archives and extracts an empty file through zstd compression and verifies it stays empty.
# @timeout: 180
# @tags: usage, archive, zstd
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-libarchive-tools-zstd-empty-file"
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
: >"$tmpdir/in/empty.txt"
bsdtar --zstd -cf "$tmpdir/a.tar.zstd" -C "$tmpdir/in" empty.txt
bsdtar -xf "$tmpdir/a.tar.zstd" -C "$tmpdir/out"
test "$(wc -c <"$tmpdir/out/empty.txt")" -eq 0

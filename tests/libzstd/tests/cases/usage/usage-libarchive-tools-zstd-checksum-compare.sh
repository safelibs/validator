#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-checksum-compare
# @title: libarchive-tools zstd checksum compare
# @description: Compares checksums before and after extraction from a zstd-compressed tar archive.
# @timeout: 180
# @tags: usage, archive, zstd
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-libarchive-tools-zstd-checksum-compare"
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
bsdtar --zstd -cf "$tmpdir/a.tar.zstd" -C "$tmpdir/in" alpha.txt
bsdtar -xf "$tmpdir/a.tar.zstd" -C "$tmpdir/out"
sha256sum "$tmpdir/in/alpha.txt" "$tmpdir/out/alpha.txt" | awk '{print $1}' >"$tmpdir/sums"
test "$(sort -u "$tmpdir/sums" | wc -l)" -eq 1

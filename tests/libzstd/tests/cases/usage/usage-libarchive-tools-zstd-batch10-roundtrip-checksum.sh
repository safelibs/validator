#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-batch10-roundtrip-checksum
# @title: libarchive-tools zstd nested member checksum
# @description: Round-trips a nested file through a zstd tar archive and verifies the SHA-256 of the extracted file matches the source.
# @timeout: 180
# @tags: usage, archive, zstd
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-libarchive-tools-zstd-batch10-roundtrip-checksum"
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
bsdtar --zstd -cf "$tmpdir/a.tar.zstd" -C "$tmpdir/in" dir/beta.txt
bsdtar -xf "$tmpdir/a.tar.zstd" -C "$tmpdir/out"
sha256sum "$tmpdir/in/dir/beta.txt" "$tmpdir/out/dir/beta.txt" | awk '{print $1}' | sort -u >"$tmpdir/sums"
test "$(wc -l <"$tmpdir/sums")" -eq 1

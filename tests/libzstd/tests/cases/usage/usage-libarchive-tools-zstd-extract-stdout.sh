#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-extract-stdout
# @title: libarchive-tools zstd extract to stdout
# @description: Extracts one archived file to stdout from a zstd-compressed tar archive.
# @timeout: 180
# @tags: usage, archive, zstd
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-libarchive-tools-zstd-extract-stdout"
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
bsdtar -xOf "$tmpdir/a.tar.zstd" dir/beta.txt >"$tmpdir/stdout.txt"
validator_assert_contains "$tmpdir/stdout.txt" 'beta payload'

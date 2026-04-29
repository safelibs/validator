#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-batch10-cwd-extract
# @title: libarchive-tools zstd extract in cwd
# @description: Extracts a zstd archive from the current working directory without -C and verifies the file lands relative to cwd.
# @timeout: 180
# @tags: usage, archive, zstd
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-libarchive-tools-zstd-batch10-cwd-extract"
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
mkdir -p "$tmpdir/out"
(cd "$tmpdir/out" && bsdtar -xf "$tmpdir/a.tar.zstd")
validator_assert_contains "$tmpdir/out/alpha.txt" 'alpha payload'

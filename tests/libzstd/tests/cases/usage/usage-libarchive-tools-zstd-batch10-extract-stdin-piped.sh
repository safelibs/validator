#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-batch10-extract-stdin-piped
# @title: libarchive-tools zstd extract from stdin pipe
# @description: Pipes a zstd archive into bsdtar -xf - via redirection and verifies a deeply nested member is extracted with its payload.
# @timeout: 180
# @tags: usage, archive, zstd
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-libarchive-tools-zstd-batch10-extract-stdin-piped"
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
bsdtar --zstd -cf "$tmpdir/a.tar.zstd" -C "$tmpdir/in" dir/sub/gamma.txt
mkdir -p "$tmpdir/out"
bsdtar -xf - -C "$tmpdir/out" <"$tmpdir/a.tar.zstd"
validator_assert_contains "$tmpdir/out/dir/sub/gamma.txt" 'gamma payload'

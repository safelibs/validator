#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-stream-member-stdout
# @title: libarchive tools zstd stream member stdout
# @description: Exercises libarchive tools zstd stream member stdout through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-libarchive-tools-zstd-stream-member-stdout"
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
cat "$tmpdir/a.tar.zstd" | bsdtar -xOf - dir/sub/gamma.txt >"$tmpdir/out.txt"
validator_assert_contains "$tmpdir/out.txt" 'gamma payload'

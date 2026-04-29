#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-batch10-extract-multi-stdout
# @title: libarchive-tools xz extract two members to stdout
# @description: Uses bsdtar -xOf to print two named members from an xz archive and verifies both payloads appear on stdout.
# @timeout: 180
# @tags: usage, archive, xz
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-libarchive-tools-xz-batch10-extract-multi-stdout"
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
bsdtar -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/in" alpha.txt dir/beta.txt
bsdtar -xOf "$tmpdir/a.tar.xz" alpha.txt dir/beta.txt >"$tmpdir/out.txt"
validator_assert_contains "$tmpdir/out.txt" 'alpha payload'
validator_assert_contains "$tmpdir/out.txt" 'beta payload'

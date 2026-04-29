#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-extract-stdout
# @title: libarchive-tools xz extract to stdout
# @description: Extracts one archived file to stdout from an xz-compressed tar archive.
# @timeout: 180
# @tags: usage, archive, xz
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-libarchive-tools-xz-extract-stdout"
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
bsdtar -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/in" dir/beta.txt
bsdtar -xOf "$tmpdir/a.tar.xz" dir/beta.txt >"$tmpdir/stdout.txt"
validator_assert_contains "$tmpdir/stdout.txt" 'beta payload'

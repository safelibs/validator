#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-batch10-xz-decompress-flag
# @title: libarchive-tools xz extract with explicit --xz
# @description: Extracts an xz archive while passing --xz to bsdtar -xf and verifies the restored file payload.
# @timeout: 180
# @tags: usage, archive, xz
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-libarchive-tools-xz-batch10-xz-decompress-flag"
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
printf 'flag payload\n' >"$tmpdir/in/alpha.txt"
bsdtar -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/in" alpha.txt
bsdtar --xz -xf "$tmpdir/a.tar.xz" -C "$tmpdir/out"
validator_assert_contains "$tmpdir/out/alpha.txt" 'flag payload'

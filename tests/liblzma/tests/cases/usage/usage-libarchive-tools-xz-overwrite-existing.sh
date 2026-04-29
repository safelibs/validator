#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-overwrite-existing
# @title: libarchive-tools xz overwrite existing
# @description: Extracts an xz-compressed tar archive over an existing file and verifies the archived content wins.
# @timeout: 180
# @tags: usage, archive, xz
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-libarchive-tools-xz-overwrite-existing"
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
bsdtar -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/in" alpha.txt
mkdir -p "$tmpdir/out"
printf 'old payload\n' >"$tmpdir/out/alpha.txt"
bsdtar -xf "$tmpdir/a.tar.xz" -C "$tmpdir/out"
validator_assert_contains "$tmpdir/out/alpha.txt" 'alpha payload'

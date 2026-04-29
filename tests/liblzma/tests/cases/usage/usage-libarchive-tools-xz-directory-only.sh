#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-directory-only
# @title: libarchive-tools xz directory only
# @description: Archives and extracts an empty directory through xz compression.
# @timeout: 180
# @tags: usage, archive, xz
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-libarchive-tools-xz-directory-only"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

make_tree() {
  mkdir -p "$tmpdir/in/dir/sub" "$tmpdir/out"
  printf 'alpha payload\n' >"$tmpdir/in/alpha.txt"
  printf 'beta payload\n' >"$tmpdir/in/dir/beta.txt"
  printf 'gamma payload\n' >"$tmpdir/in/dir/sub/gamma.txt"
  printf 'space payload\n' >"$tmpdir/in/space name.txt"
}

mkdir -p "$tmpdir/in/empty" "$tmpdir/out"
bsdtar -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/in" empty
bsdtar -xf "$tmpdir/a.tar.xz" -C "$tmpdir/out"
validator_require_dir "$tmpdir/out/empty"

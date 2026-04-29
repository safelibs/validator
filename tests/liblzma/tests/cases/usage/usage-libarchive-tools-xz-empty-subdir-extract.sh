#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-empty-subdir-extract
# @title: libarchive tools xz empty subdirectory extract
# @description: Exercises libarchive tools xz empty subdirectory extract through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-libarchive-tools-xz-empty-subdir-extract"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

make_tree() {
  mkdir -p "$tmpdir/in/dir/sub" "$tmpdir/out"
  printf 'alpha payload\n' >"$tmpdir/in/alpha.txt"
  printf 'beta payload\n' >"$tmpdir/in/dir/beta.txt"
  printf 'gamma payload\n' >"$tmpdir/in/dir/sub/gamma.txt"
  printf 'space payload\n' >"$tmpdir/in/space name.txt"
}

mkdir -p "$tmpdir/in/empty/sub" "$tmpdir/out"
bsdtar -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/in" empty
bsdtar -xf "$tmpdir/a.tar.xz" -C "$tmpdir/out"
validator_require_dir "$tmpdir/out/empty/sub"

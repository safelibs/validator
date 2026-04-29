#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-batch10-deep-nested-extract
# @title: libarchive-tools xz deep nested extract
# @description: Round-trips a five-level nested file through an xz tar and verifies the leaf path and payload survive extraction.
# @timeout: 180
# @tags: usage, archive, xz
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-libarchive-tools-xz-batch10-deep-nested-extract"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

make_tree() {
  mkdir -p "$tmpdir/in/dir/sub" "$tmpdir/out"
  printf 'alpha payload\n' >"$tmpdir/in/alpha.txt"
  printf 'beta payload\n' >"$tmpdir/in/dir/beta.txt"
  printf 'gamma payload\n' >"$tmpdir/in/dir/sub/gamma.txt"
  printf 'space payload\n' >"$tmpdir/in/space name.txt"
}

mkdir -p "$tmpdir/in/a/b/c/d/e" "$tmpdir/out"
printf 'deep payload\n' >"$tmpdir/in/a/b/c/d/e/leaf.txt"
bsdtar -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/in" a
bsdtar -xf "$tmpdir/a.tar.xz" -C "$tmpdir/out"
validator_assert_contains "$tmpdir/out/a/b/c/d/e/leaf.txt" 'deep payload'

#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-stream-extract
# @title: libarchive-tools xz stream extract
# @description: Streams an xz-compressed tar archive through stdin and extracts its contents.
# @timeout: 180
# @tags: usage, archive, xz
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-libarchive-tools-xz-stream-extract"
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
cat "$tmpdir/a.tar.xz" | bsdtar -xf - -C "$tmpdir/out"
validator_assert_contains "$tmpdir/out/alpha.txt" 'alpha payload'

#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-dotfile-stream-extract
# @title: libarchive tools zstd dotfile stream extract
# @description: Exercises libarchive tools zstd dotfile stream extract through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-libarchive-tools-zstd-dotfile-stream-extract"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

make_tree() {
  mkdir -p "$tmpdir/in/dir/sub" "$tmpdir/out"
  printf 'alpha payload\n' >"$tmpdir/in/alpha.txt"
  printf 'beta payload\n' >"$tmpdir/in/dir/beta.txt"
  printf 'gamma payload\n' >"$tmpdir/in/dir/sub/gamma.txt"
  printf 'space payload\n' >"$tmpdir/in/space name.txt"
}

mkdir -p "$tmpdir/in"
printf 'dotfile payload\n' >"$tmpdir/in/.hidden"
bsdtar --zstd -cf "$tmpdir/a.tar.zstd" -C "$tmpdir/in" .hidden
cat "$tmpdir/a.tar.zstd" | bsdtar -xOf - .hidden >"$tmpdir/out.txt"
validator_assert_contains "$tmpdir/out.txt" 'dotfile payload'

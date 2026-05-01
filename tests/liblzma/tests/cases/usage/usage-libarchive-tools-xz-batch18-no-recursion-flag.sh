#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-batch18-no-recursion-flag
# @title: bsdtar -n no-recursion with xz compression
# @description: Builds an xz-compressed tar with bsdtar -n so a directory argument is recorded without descent, then asserts the listing contains the directory entry alone and not its children.
# @timeout: 180
# @tags: usage, archive, xz, recursion
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/src/dir/inner" "$tmpdir/out"
printf 'inside content alpha\n' >"$tmpdir/src/dir/alpha.txt"
printf 'inside content gamma\n' >"$tmpdir/src/dir/inner/gamma.txt"

bsdtar -n -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/src" dir

magic_hex=$(head -c 6 "$tmpdir/a.tar.xz" | od -An -tx1 | tr -d ' \n')
test "$magic_hex" = "fd377a585a00"

bsdtar -tf "$tmpdir/a.tar.xz" >"$tmpdir/list"
validator_assert_contains "$tmpdir/list" 'dir/'

if grep -q 'alpha.txt' "$tmpdir/list"; then
  printf 'expected -n to skip dir contents but found alpha.txt\n' >&2
  cat "$tmpdir/list" >&2
  exit 1
fi
if grep -q 'gamma.txt' "$tmpdir/list"; then
  printf 'expected -n to skip dir contents but found gamma.txt\n' >&2
  cat "$tmpdir/list" >&2
  exit 1
fi

entry_count=$(grep -c . "$tmpdir/list")
test "$entry_count" -eq 1

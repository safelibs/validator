#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-batch14-absolute-paths-keep
# @title: bsdtar xz -P preserves absolute paths
# @description: Archives an absolute path into tar.xz with -P; bsdtar must keep the leading slash in the listing and the listed entry must equal the absolute path.
# @timeout: 180
# @tags: usage, archive, xz
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/src"
printf 'absolute keep payload\n' >"$tmpdir/src/abs.txt"
abs_path="$tmpdir/src/abs.txt"

bsdtar -P -cJf "$tmpdir/a.tar.xz" "$abs_path"

magic_hex=$(head -c 6 "$tmpdir/a.tar.xz" | od -An -tx1 | tr -d ' \n')
test "$magic_hex" = "fd377a585a00"

bsdtar -tf "$tmpdir/a.tar.xz" >"$tmpdir/list.txt"

# With -P, the absolute form must appear verbatim in the listing.
test "$(grep -cFx "$abs_path" "$tmpdir/list.txt")" = "1"

# Bare relative form (without leading /) must NOT be present.
relpath="${abs_path#/}"
if grep -Fxq "$relpath" "$tmpdir/list.txt"; then
  printf 'unexpected stripped path in listing:\n' >&2
  cat "$tmpdir/list.txt" >&2
  exit 1
fi

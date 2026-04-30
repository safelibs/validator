#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-batch13-absolute-paths-stripped
# @title: bsdtar xz strips leading slash by default
# @description: Archives a file by absolute path through tar.xz; bsdtar must strip the leading slash by default and -tf must not list any path beginning with /.
# @timeout: 180
# @tags: usage, archive, xz
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/src" "$tmpdir/out"
printf 'absolute payload\n' >"$tmpdir/src/abs.txt"
abs_path="$tmpdir/src/abs.txt"

# Archive using the absolute path; bsdtar default behavior (no -P) strips '/'.
bsdtar -cJf "$tmpdir/a.tar.xz" "$abs_path" 2>"$tmpdir/err.txt"

# .xz magic
magic_hex=$(head -c 6 "$tmpdir/a.tar.xz" | od -An -tx1 | tr -d ' \n')
test "$magic_hex" = "fd377a585a00"

bsdtar -tf "$tmpdir/a.tar.xz" >"$tmpdir/list.txt"

# No listed entry may start with '/'
if grep -Eq '^/' "$tmpdir/list.txt"; then
  printf 'unexpected absolute path in listing:\n' >&2
  cat "$tmpdir/list.txt" >&2
  exit 1
fi

# The relative form (leading slash stripped) must be present exactly once.
relpath="${abs_path#/}"
test "$(grep -cFx "$relpath" "$tmpdir/list.txt")" = "1"

# Extracting into out/ creates the file at out/<relpath> (no escape into /)
bsdtar -xf "$tmpdir/a.tar.xz" -C "$tmpdir/out"
test -f "$tmpdir/out/$relpath"
cmp "$tmpdir/src/abs.txt" "$tmpdir/out/$relpath"

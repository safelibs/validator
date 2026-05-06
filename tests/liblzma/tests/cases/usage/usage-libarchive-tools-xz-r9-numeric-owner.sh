#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-r9-numeric-owner
# @title: bsdtar xz numeric-owner verbose listing
# @description: Creates an xz tarball and verifies bsdtar -tv --numeric-owner produces a listing whose owner field is numeric.
# @timeout: 180
# @tags: usage, archive, compression
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in"
printf 'numeric-owner\n' >"$tmpdir/in/file.txt"
( cd "$tmpdir/in" && bsdtar -cJf "$tmpdir/a.tar.xz" file.txt )

bsdtar -tvf "$tmpdir/a.tar.xz" --numeric-owner >"$tmpdir/list.txt"
# Owner field is the third whitespace-separated token. With --numeric-owner the
# entry should be of the form "numericuid/numericgid" (digits and a slash).
awk '{print $3}' "$tmpdir/list.txt" >"$tmpdir/own.txt"
grep -Eq '^[0-9]+/[0-9]+$' "$tmpdir/own.txt" || {
  printf 'unexpected owner field:\n' >&2; cat "$tmpdir/list.txt" >&2; exit 1;
}

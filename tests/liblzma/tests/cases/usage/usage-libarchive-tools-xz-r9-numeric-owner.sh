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
# bsdtar --numeric-owner prints "<perm> <links> <uid> <gid> <size> <date> <name>".
# Verify both the uid (column 3) and the gid (column 4) are decimal integers.
awk 'NR==1 {print $3, $4}' "$tmpdir/list.txt" >"$tmpdir/own.txt"
grep -Eq '^[0-9]+ [0-9]+$' "$tmpdir/own.txt" || {
  printf 'unexpected owner field:\n' >&2; cat "$tmpdir/list.txt" >&2; exit 1;
}

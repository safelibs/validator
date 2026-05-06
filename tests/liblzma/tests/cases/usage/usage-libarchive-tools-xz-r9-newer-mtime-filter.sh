#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-r9-newer-mtime-filter
# @title: bsdtar xz --newer-mtime selective add
# @description: Creates two files with disparate mtimes and uses bsdtar -cJf --newer-mtime to include only the newer file in the resulting xz tarball.
# @timeout: 180
# @tags: usage, archive, compression
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in"
printf 'old\n' >"$tmpdir/in/old.txt"
printf 'new\n' >"$tmpdir/in/new.txt"
touch -d '2010-01-01 00:00:00' "$tmpdir/in/old.txt"
touch -d '2025-01-01 00:00:00' "$tmpdir/in/new.txt"

( cd "$tmpdir/in" && bsdtar --newer-mtime '2020-01-01 00:00:00' -cJf "$tmpdir/a.tar.xz" old.txt new.txt )

bsdtar -tf "$tmpdir/a.tar.xz" >"$tmpdir/list.txt"
grep -q '^new.txt$' "$tmpdir/list.txt" || { printf 'missing new.txt\n' >&2; cat "$tmpdir/list.txt" >&2; exit 1; }
if grep -q '^old.txt$' "$tmpdir/list.txt"; then
  printf 'old.txt should have been excluded\n' >&2; cat "$tmpdir/list.txt" >&2; exit 1;
fi

#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-r9-multifile-listing-count
# @title: bsdtar xz multi-file listing count
# @description: Builds an xz tarball with five small files and verifies bsdtar -tf prints exactly five entries.
# @timeout: 180
# @tags: usage, archive, compression
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in"
for i in 1 2 3 4 5; do
  printf 'content-%s\n' "$i" >"$tmpdir/in/f$i.txt"
done

( cd "$tmpdir/in" && bsdtar -cJf "$tmpdir/a.tar.xz" f1.txt f2.txt f3.txt f4.txt f5.txt )

count=$(bsdtar -tf "$tmpdir/a.tar.xz" | wc -l)
[[ "$count" == "5" ]] || { printf 'expected 5 entries, got %s\n' "$count" >&2; exit 1; }

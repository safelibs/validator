#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-r17-bsdtar-tjf-lists-three-entries
# @title: bsdtar -tJf lists exactly three entries on a 3-file tar.xz
# @description: Builds a 3-file tar.xz, lists its members with bsdtar -tJf, and asserts the listing has exactly three non-empty lines, pinning libarchive's xz-tar enumeration count.
# @timeout: 60
# @tags: usage, bsdtar, xz, listing
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir "$tmpdir/src"
printf 'one\n'   >"$tmpdir/src/one.txt"
printf 'two\n'   >"$tmpdir/src/two.txt"
printf 'three\n' >"$tmpdir/src/three.txt"

(cd "$tmpdir/src" && bsdtar -cJf "$tmpdir/out.tar.xz" one.txt two.txt three.txt)
bsdtar -tJf "$tmpdir/out.tar.xz" >"$tmpdir/list.txt"

count=$(grep -c . "$tmpdir/list.txt")
[[ "$count" -eq 3 ]] || {
  printf 'expected 3 entries, got %s\n' "$count" >&2
  exit 1
}

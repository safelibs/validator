#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-batch16-list-100-entries
# @title: bsdtar -tf 100 entries
# @description: Builds an xz tarball with exactly 100 file entries and confirms bsdtar -tf lists exactly 100 names.
# @timeout: 240
# @tags: usage, archive, xz, list
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/src"
for i in $(seq 1 100); do
  printf 'entry %03d body\n' "$i" >"$tmpdir/src/file-$(printf '%03d' "$i").txt"
done

# Sanity: 100 source files prepared.
src_count=$(find "$tmpdir/src" -maxdepth 1 -type f | wc -l)
test "$src_count" -eq 100

bsdtar -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/src" .

bsdtar -tf "$tmpdir/a.tar.xz" >"$tmpdir/list"

# Filter to file entries (skip the './' directory entry if present).
file_count=$(grep -E '^\./file-[0-9]{3}\.txt$' "$tmpdir/list" | wc -l)
test "$file_count" -eq 100

# Spot-check the first and last entries.
validator_assert_contains "$tmpdir/list" './file-001.txt'
validator_assert_contains "$tmpdir/list" './file-100.txt'

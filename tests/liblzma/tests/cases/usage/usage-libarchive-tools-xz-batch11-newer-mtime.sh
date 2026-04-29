#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-batch11-newer-mtime
# @title: bsdtar xz newer mtime filter
# @description: Creates an xz archive using a newer-than mtime filter and verifies older files are skipped.
# @timeout: 180
# @tags: usage, archive, xz
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-libarchive-tools-xz-batch11-newer-mtime"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

make_archive() {
  mkdir -p "$tmpdir/src/top/nested" "$tmpdir/src/space dir"
  printf 'alpha payload\n' >"$tmpdir/src/top/alpha.txt"
  printf 'beta payload\n' >"$tmpdir/src/top/nested/beta.txt"
  printf 'space payload\n' >"$tmpdir/src/space dir/file name.txt"
  printf 'skip payload\n' >"$tmpdir/src/top/skip.tmp"
  bsdtar -acf "$tmpdir/archive.tar.xz" -C "$tmpdir/src" .
}

mkdir -p "$tmpdir/src"
printf 'old\n' >"$tmpdir/src/old.txt"
printf 'new\n' >"$tmpdir/src/new.txt"
touch -t 202001010000 "$tmpdir/src/old.txt"
touch -t 202501010000 "$tmpdir/src/new.txt"
bsdtar -acf "$tmpdir/archive.tar.xz" --newer-mtime "2024-01-01" -C "$tmpdir/src" old.txt new.txt
bsdtar -tf "$tmpdir/archive.tar.xz" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'new.txt'
if grep -Fq 'old.txt' "$tmpdir/out"; then exit 1; fi

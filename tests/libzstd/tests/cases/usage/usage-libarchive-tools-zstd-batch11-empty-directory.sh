#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-batch11-empty-directory
# @title: bsdtar zstd empty directory
# @description: Archives and extracts an empty directory inside a zstd-compressed tar archive.
# @timeout: 180
# @tags: usage, archive, zstd
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-libarchive-tools-zstd-batch11-empty-directory"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

make_archive() {
  mkdir -p "$tmpdir/src/top/nested" "$tmpdir/src/space dir"
  printf 'alpha payload\n' >"$tmpdir/src/top/alpha.txt"
  printf 'beta payload\n' >"$tmpdir/src/top/nested/beta.txt"
  printf 'space payload\n' >"$tmpdir/src/space dir/file name.txt"
  printf 'skip payload\n' >"$tmpdir/src/top/skip.tmp"
  bsdtar -acf "$tmpdir/archive.tar.zst" -C "$tmpdir/src" .
}

mkdir -p "$tmpdir/src/empty"
bsdtar -acf "$tmpdir/archive.tar.zst" -C "$tmpdir/src" empty
mkdir "$tmpdir/outdir"
bsdtar -xf "$tmpdir/archive.tar.zst" -C "$tmpdir/outdir"
test -d "$tmpdir/outdir/empty"

#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-batch11-exclude-vcs
# @title: bsdtar zstd exclude VCS
# @description: Creates a zstd archive with VCS metadata excluded by bsdtar.
# @timeout: 180
# @tags: usage, archive, zstd
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-libarchive-tools-zstd-batch11-exclude-vcs"
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

mkdir -p "$tmpdir/src/.git"
printf 'data\n' >"$tmpdir/src/data.txt"
printf 'config\n' >"$tmpdir/src/.git/config"
bsdtar --exclude-vcs -acf "$tmpdir/archive.tar.zst" -C "$tmpdir/src" .
bsdtar -tf "$tmpdir/archive.tar.zst" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" './data.txt'
if grep -Fq '.git' "$tmpdir/out"; then exit 1; fi

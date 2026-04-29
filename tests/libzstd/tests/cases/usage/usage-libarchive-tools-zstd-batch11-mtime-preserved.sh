#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-batch11-mtime-preserved
# @title: bsdtar zstd mtime preserved
# @description: Round-trips a fixed modification time through a zstd-compressed tar archive.
# @timeout: 180
# @tags: usage, archive, zstd
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-libarchive-tools-zstd-batch11-mtime-preserved"
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

mkdir -p "$tmpdir/src"
printf 'dated\n' >"$tmpdir/src/dated.txt"
touch -t 202001020304 "$tmpdir/src/dated.txt"
bsdtar -acf "$tmpdir/archive.tar.zst" -C "$tmpdir/src" dated.txt
mkdir "$tmpdir/outdir"
bsdtar -xf "$tmpdir/archive.tar.zst" -C "$tmpdir/outdir"
test "$(date -u -r "$tmpdir/outdir/dated.txt" +%Y%m%d%H%M)" = 202001020304

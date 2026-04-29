#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-batch11-mode-preserved
# @title: bsdtar zstd mode preserved
# @description: Round-trips executable mode bits through a zstd-compressed tar archive.
# @timeout: 180
# @tags: usage, archive, zstd
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-libarchive-tools-zstd-batch11-mode-preserved"
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
printf '#!/bin/sh\n' >"$tmpdir/src/tool.sh"
chmod 700 "$tmpdir/src/tool.sh"
bsdtar -acf "$tmpdir/archive.tar.zst" -C "$tmpdir/src" tool.sh
mkdir "$tmpdir/outdir"
bsdtar -xf "$tmpdir/archive.tar.zst" -C "$tmpdir/outdir"
test "$(stat -c %a "$tmpdir/outdir/tool.sh")" = 700

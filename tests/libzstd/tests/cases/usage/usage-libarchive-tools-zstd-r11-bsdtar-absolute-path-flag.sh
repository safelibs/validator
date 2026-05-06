#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r11-bsdtar-absolute-path-flag
# @title: bsdtar --zstd -P preserves the leading slash in pathnames
# @description: Builds a zstd tar with -P from an absolute file path and verifies the recorded entry name retains its leading slash in the verbose listing instead of being silently stripped.
# @timeout: 120
# @tags: usage, archive, zstd, absolute-paths
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

abs="$tmpdir/abs-payload.txt"
printf 'absolute\n' >"$abs"

bsdtar --zstd -cf "$tmpdir/abs.tar.zst" -P "$abs"
bsdtar -tf "$tmpdir/abs.tar.zst" >"$tmpdir/list"

grep -Fx "$abs" "$tmpdir/list" >/dev/null

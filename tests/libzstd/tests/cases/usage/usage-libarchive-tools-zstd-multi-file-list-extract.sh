#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-multi-file-list-extract
# @title: bsdtar zstd multi-file selective extract via -T
# @description: Creates a multi-file zstd-compressed tar then extracts only the members named in a newline-delimited file list passed via -T and verifies that listed members are restored while unlisted members are not.
# @timeout: 180
# @tags: usage, archive, zstd
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in" "$tmpdir/out"
printf 'alpha payload\n' >"$tmpdir/in/alpha.txt"
printf 'beta payload\n' >"$tmpdir/in/beta.txt"
printf 'gamma payload\n' >"$tmpdir/in/gamma.txt"
printf 'delta payload\n' >"$tmpdir/in/delta.txt"

bsdtar --zstd -cf "$tmpdir/a.tar.zst" -C "$tmpdir/in" \
  alpha.txt beta.txt gamma.txt delta.txt
validator_require_file "$tmpdir/a.tar.zst"

magic=$(od -An -N4 -tx1 "$tmpdir/a.tar.zst" | tr -d ' \n')
test "$magic" = "28b52ffd"

# Selective extraction list: alpha and gamma only.
printf 'alpha.txt\ngamma.txt\n' >"$tmpdir/want.list"

bsdtar -xf "$tmpdir/a.tar.zst" -C "$tmpdir/out" -T "$tmpdir/want.list"

validator_require_file "$tmpdir/out/alpha.txt"
validator_require_file "$tmpdir/out/gamma.txt"
test ! -e "$tmpdir/out/beta.txt"
test ! -e "$tmpdir/out/delta.txt"

validator_assert_contains "$tmpdir/out/alpha.txt" 'alpha payload'
validator_assert_contains "$tmpdir/out/gamma.txt" 'gamma payload'

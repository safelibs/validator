#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-batch12-include-exclude-pair
# @title: bsdtar zstd positional include with --exclude exclusion
# @description: Lists a zstd-compressed tar passing a positional name pattern as the member filter and --exclude to subtract one match, asserting only the included-but-not-excluded member surfaces.
# @timeout: 180
# @tags: usage, archive, zstd
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in"
printf 'alpha payload\n' >"$tmpdir/in/alpha.txt"
printf 'beta payload\n'  >"$tmpdir/in/beta.txt"
printf 'gamma payload\n' >"$tmpdir/in/gamma.log"
printf 'delta payload\n' >"$tmpdir/in/delta.log"

bsdtar --zstd -cf "$tmpdir/a.tar.zst" -C "$tmpdir/in" \
  alpha.txt beta.txt gamma.log delta.log
validator_require_file "$tmpdir/a.tar.zst"

magic=$(od -An -N4 -tx1 "$tmpdir/a.tar.zst" | tr -d ' \n')
test "$magic" = "28b52ffd"

# Positional pattern '*.log' keeps log members, --exclude drops gamma.log.
# Only delta.log should appear in the listing.
bsdtar --exclude='gamma*' -tf "$tmpdir/a.tar.zst" '*.log' >"$tmpdir/list"

validator_assert_contains "$tmpdir/list" 'delta.log'
if grep -Fq 'gamma.log' "$tmpdir/list"; then exit 1; fi
if grep -Fq 'alpha.txt' "$tmpdir/list"; then exit 1; fi
if grep -Fq 'beta.txt'  "$tmpdir/list"; then exit 1; fi

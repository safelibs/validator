#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r10-bsdtar-multi-substitute
# @title: bsdtar zstd applies two -s substitution rules
# @description: Creates a zstd-compressed tar with two chained -s path-rewrite rules, then asserts the listing reflects both rewrites and that the originally-named entries no longer appear in the archive.
# @timeout: 180
# @tags: usage, archive, zstd, substitute
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in"
printf 'alpha payload\n' >"$tmpdir/in/alpha.txt"
printf 'beta payload\n' >"$tmpdir/in/beta.txt"

# Two -s rules: alpha→aleph, beta→bet. Both must apply during creation.
bsdtar --zstd \
  -s '/alpha/aleph/' \
  -s '/beta/bet/' \
  -cf "$tmpdir/a.tar.zst" -C "$tmpdir/in" alpha.txt beta.txt

bsdtar -tf "$tmpdir/a.tar.zst" >"$tmpdir/list"
validator_assert_contains "$tmpdir/list" 'aleph.txt'
validator_assert_contains "$tmpdir/list" 'bet.txt'

! grep -Fq 'alpha.txt' "$tmpdir/list"
! grep -Fq 'beta.txt' "$tmpdir/list"

#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-batch10-exclude-multi
# @title: libarchive-tools zstd multiple exclude patterns
# @description: Builds a zstd tar with two --exclude patterns and verifies only the unmatched member appears in the listing.
# @timeout: 180
# @tags: usage, archive, zstd
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-libarchive-tools-zstd-batch10-exclude-multi"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

make_tree() {
  mkdir -p "$tmpdir/in/dir/sub" "$tmpdir/out"
  printf 'alpha payload\n' >"$tmpdir/in/alpha.txt"
  printf 'beta payload\n' >"$tmpdir/in/dir/beta.txt"
  printf 'gamma payload\n' >"$tmpdir/in/dir/sub/gamma.txt"
  printf 'space payload\n' >"$tmpdir/in/space name.txt"
}

make_tree
bsdtar --exclude '*alpha*' --exclude '*gamma*' --zstd -cf "$tmpdir/a.tar.zstd" -C "$tmpdir/in" .
bsdtar -tf "$tmpdir/a.tar.zstd" >"$tmpdir/list"
validator_assert_contains "$tmpdir/list" 'beta.txt'
if grep -Fq 'alpha.txt' "$tmpdir/list"; then exit 1; fi
if grep -Fq 'gamma.txt' "$tmpdir/list"; then exit 1; fi

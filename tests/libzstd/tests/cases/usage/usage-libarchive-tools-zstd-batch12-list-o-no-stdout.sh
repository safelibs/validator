#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-batch12-list-o-no-stdout
# @title: bsdtar zstd -t lists members without emitting content
# @description: Lists a zstd-compressed tar with bsdtar -tf and asserts the listing prints the member name on stdout while never leaking the archived payload bytes onto stdout.
# @timeout: 180
# @tags: usage, archive, zstd
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in"
printf 'unique-marker-payload\n' >"$tmpdir/in/marker.txt"

bsdtar --zstd -cf "$tmpdir/a.tar.zst" -C "$tmpdir/in" marker.txt
validator_require_file "$tmpdir/a.tar.zst"

magic=$(od -An -N4 -tx1 "$tmpdir/a.tar.zst" | tr -d ' \n')
test "$magic" = "28b52ffd"

# -t lists names; the listing must print the member name and must not leak
# the file payload onto stdout.
bsdtar -tf "$tmpdir/a.tar.zst" >"$tmpdir/stdout.txt"

validator_assert_contains "$tmpdir/stdout.txt" 'marker.txt'
if grep -Fq 'unique-marker-payload' "$tmpdir/stdout.txt"; then exit 1; fi

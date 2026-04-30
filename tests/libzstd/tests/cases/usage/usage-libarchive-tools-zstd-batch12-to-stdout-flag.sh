#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-batch12-to-stdout-flag
# @title: bsdtar zstd --to-stdout extracts member contents to stdout
# @description: Extracts a single member from a zstd-compressed tar using bsdtar's GNU-compatible --to-stdout flag and verifies the payload reaches stdout while the on-disk extraction directory stays empty.
# @timeout: 180
# @tags: usage, archive, zstd
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in" "$tmpdir/out"
printf 'to-stdout payload\n' >"$tmpdir/in/marker.txt"

bsdtar --zstd -cf "$tmpdir/a.tar.zst" -C "$tmpdir/in" marker.txt
validator_require_file "$tmpdir/a.tar.zst"

magic=$(od -An -N4 -tx1 "$tmpdir/a.tar.zst" | tr -d ' \n')
test "$magic" = "28b52ffd"

# --to-stdout is the long form of -O; payload should be on stdout, not on disk.
# Place --to-stdout before -f so it is not parsed as the -f argument.
( cd "$tmpdir/out" && bsdtar --to-stdout -xf "$tmpdir/a.tar.zst" marker.txt ) >"$tmpdir/stdout.txt"

validator_assert_contains "$tmpdir/stdout.txt" 'to-stdout payload'

# Nothing should have been materialized in the extraction directory.
test -z "$(ls -A "$tmpdir/out")"

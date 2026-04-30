#!/usr/bin/env bash
# @testcase: usage-tar-totals-summary
# @title: tar totals summary on create
# @description: Creates an archive with tar --totals and verifies the totals line on stderr reports a positive byte count.
# @timeout: 180
# @tags: usage, tar, archive
# @client: tar

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-tar-totals-summary"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/tree"
printf 'alpha payload\n' >"$tmpdir/tree/alpha.txt"
printf 'beta payload data\n' >"$tmpdir/tree/beta.txt"

tar --totals -cf "$tmpdir/archive.tar" -C "$tmpdir/tree" alpha.txt beta.txt 2>"$tmpdir/err"

validator_require_file "$tmpdir/archive.tar"
validator_assert_contains "$tmpdir/err" 'Total bytes written:'

bytes=$(grep -oE 'Total bytes written: [0-9]+' "$tmpdir/err" | grep -oE '[0-9]+')
test -n "$bytes"
test "$bytes" -gt 0

tar -tf "$tmpdir/archive.tar" >"$tmpdir/list"
validator_assert_contains "$tmpdir/list" 'alpha.txt'
validator_assert_contains "$tmpdir/list" 'beta.txt'

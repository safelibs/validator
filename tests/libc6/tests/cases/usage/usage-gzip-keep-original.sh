#!/usr/bin/env bash
# @testcase: usage-gzip-keep-original
# @title: gzip keep original
# @description: Compresses a file with gzip -k and verifies both the original and compressed files exist with restorable content.
# @timeout: 180
# @tags: usage, gzip, archive
# @client: gzip

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gzip-keep-original"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'gzip keep payload\n' >"$tmpdir/in.txt"
gzip -k "$tmpdir/in.txt"
test -f "$tmpdir/in.txt"
test -f "$tmpdir/in.txt.gz"
gunzip -c "$tmpdir/in.txt.gz" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'gzip keep payload'

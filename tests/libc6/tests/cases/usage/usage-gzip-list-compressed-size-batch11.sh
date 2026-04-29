#!/usr/bin/env bash
# @testcase: usage-gzip-list-compressed-size-batch11
# @title: gzip list compressed size
# @description: Lists gzip compressed and uncompressed size columns.
# @timeout: 180
# @tags: usage, gzip, compression
# @client: gzip

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gzip-list-compressed-size-batch11"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'gzip listing payload\n' >"$tmpdir/plain.txt"
gzip -k "$tmpdir/plain.txt"
gzip -l "$tmpdir/plain.txt.gz" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'compressed'
validator_assert_contains "$tmpdir/out" 'uncompressed'

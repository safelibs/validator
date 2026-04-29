#!/usr/bin/env bash
# @testcase: usage-gzip-roundtrip
# @title: gzip compresses file
# @description: Compresses and decompresses a text file with gzip.
# @timeout: 120
# @tags: usage, compression
# @client: gzip

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gzip-roundtrip"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'gzip payload\n' >"$tmpdir/plain.txt"
gzip -c "$tmpdir/plain.txt" >"$tmpdir/plain.txt.gz"
gzip -dc "$tmpdir/plain.txt.gz" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'gzip payload'

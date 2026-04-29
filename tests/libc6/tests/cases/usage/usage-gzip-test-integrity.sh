#!/usr/bin/env bash
# @testcase: usage-gzip-test-integrity
# @title: gzip integrity check
# @description: Runs gzip integrity validation on a generated compressed stream.
# @timeout: 180
# @tags: usage, compression
# @client: gzip

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gzip-test-integrity"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'gzip integrity payload\n' >"$tmpdir/plain.txt"
gzip -c "$tmpdir/plain.txt" >"$tmpdir/plain.txt.gz"
gzip -tv "$tmpdir/plain.txt.gz" >"$tmpdir/out" 2>&1
validator_assert_contains "$tmpdir/out" 'OK'

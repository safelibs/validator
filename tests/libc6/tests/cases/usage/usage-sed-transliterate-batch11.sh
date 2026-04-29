#!/usr/bin/env bash
# @testcase: usage-sed-transliterate-batch11
# @title: sed transliterate
# @description: Transforms a stream with sed transliteration.
# @timeout: 180
# @tags: usage, sed, stream
# @client: sed

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-sed-transliterate-batch11"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'abc xyz\n' >"$tmpdir/in.txt"
sed 'y/abc/ABC/' "$tmpdir/in.txt" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'ABC xyz'

#!/usr/bin/env bash
# @testcase: usage-gawk-string-upper
# @title: gawk uppercase transform
# @description: Converts a field to uppercase with gawk and verifies the transformed output.
# @timeout: 180
# @tags: usage, gawk, text
# @client: gawk

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gawk-string-upper"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'alpha\n' >"$tmpdir/in.txt"
gawk '{print toupper($1)}' "$tmpdir/in.txt" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'ALPHA'

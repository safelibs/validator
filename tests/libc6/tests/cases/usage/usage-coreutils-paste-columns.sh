#!/usr/bin/env bash
# @testcase: usage-coreutils-paste-columns
# @title: coreutils paste columns
# @description: Joins two text columns with paste and verifies the merged output.
# @timeout: 180
# @tags: usage, coreutils, text
# @client: coreutils

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-coreutils-paste-columns"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'alpha\nbeta\n' >"$tmpdir/left.txt"
printf '1\n2\n' >"$tmpdir/right.txt"
paste -d ':' "$tmpdir/left.txt" "$tmpdir/right.txt" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'alpha:1'

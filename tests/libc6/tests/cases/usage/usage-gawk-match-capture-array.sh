#!/usr/bin/env bash
# @testcase: usage-gawk-match-capture-array
# @title: gawk match capture array
# @description: Captures parenthesised regex groups via gawk match() into an array and verifies each captured field.
# @timeout: 180
# @tags: usage, gawk, regex
# @client: gawk

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gawk-match-capture-array"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf '2026-04-29 release\n' >"$tmpdir/in.txt"

gawk '{
  if (match($0, /([0-9]+)-([0-9]+)-([0-9]+)/, arr)) {
    printf "year=%s month=%s day=%s\n", arr[1], arr[2], arr[3]
  }
}' "$tmpdir/in.txt" >"$tmpdir/out"

validator_assert_contains "$tmpdir/out" 'year=2026'
validator_assert_contains "$tmpdir/out" 'month=04'
validator_assert_contains "$tmpdir/out" 'day=29'

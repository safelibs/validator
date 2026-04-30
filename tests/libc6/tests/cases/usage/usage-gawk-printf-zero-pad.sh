#!/usr/bin/env bash
# @testcase: usage-gawk-printf-zero-pad
# @title: gawk printf zero-padded integer
# @description: Uses gawk printf "%05d" to format integers with leading zeros and verifies the resulting fixed-width values.
# @timeout: 180
# @tags: usage, gawk, format
# @client: gawk

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gawk-printf-zero-pad"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf '7\n42\n1234\n' >"$tmpdir/in"
gawk '{ printf "%05d\n", $1 }' "$tmpdir/in" >"$tmpdir/out"

validator_assert_contains "$tmpdir/out" '00007'
validator_assert_contains "$tmpdir/out" '00042'
validator_assert_contains "$tmpdir/out" '01234'

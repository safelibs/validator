#!/usr/bin/env bash
# @testcase: usage-gawk-field-sum
# @title: gawk sums fields
# @description: Sums numeric fields from tabular input with gawk.
# @timeout: 120
# @tags: usage, cli
# @client: gawk

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gawk-field-sum"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'a 2\nb 5\n' | gawk '{sum += $2} END {print "sum=" sum}' >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'sum=7'

#!/usr/bin/env bash
# @testcase: usage-gawk-csv-aggregate
# @title: gawk CSV aggregation
# @description: Aggregates comma-separated numeric fields through gawk record processing.
# @timeout: 180
# @tags: usage, text
# @client: gawk

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gawk-csv-aggregate"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'name,value\nalpha,2\nbeta,5\n' | gawk -F, 'NR > 1 {sum += $2} END {print "sum=" sum}' >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'sum=7'

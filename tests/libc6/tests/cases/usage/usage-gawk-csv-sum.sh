#!/usr/bin/env bash
# @testcase: usage-gawk-csv-sum
# @title: gawk field sum
# @description: Exercises gawk CSV field sum through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: gawk

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gawk-csv-sum"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'name,count\nalpha,3\nbeta,4\n' >"$tmpdir/input.csv"
gawk -F, 'NR > 1 {sum += $2} END {print sum}' "$tmpdir/input.csv" >"$tmpdir/out"
grep -Fxq '7' "$tmpdir/out"

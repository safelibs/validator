#!/usr/bin/env bash
# @testcase: usage-gawk-number-format
# @title: gawk numeric formatting
# @description: Aggregates decimal values with gawk and verifies formatted numeric output.
# @timeout: 180
# @tags: usage, cli
# @client: gawk

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gawk-number-format"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf '3.5\n4.5\n' >"$tmpdir/in.txt"
gawk '{sum += $1} END {printf "sum=%.1f\n", sum}' "$tmpdir/in.txt" >"$tmpdir/out"
grep -Fxq 'sum=8.0' "$tmpdir/out"

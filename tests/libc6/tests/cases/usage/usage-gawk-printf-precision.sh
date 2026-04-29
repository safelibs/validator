#!/usr/bin/env bash
# @testcase: usage-gawk-printf-precision
# @title: gawk printf precision
# @description: Formats one third with gawk printf %.3f and verifies the truncated three-digit precision.
# @timeout: 180
# @tags: usage, gawk, format
# @client: gawk

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gawk-printf-precision"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gawk 'BEGIN { printf "%.3f\n", 1.0/3 }' >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" '0.333'

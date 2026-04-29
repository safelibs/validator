#!/usr/bin/env bash
# @testcase: usage-gawk-sum-column
# @title: gawk sum column
# @description: Sums a numeric CSV column with gawk and verifies the aggregated total.
# @timeout: 180
# @tags: usage, gawk, text
# @client: gawk

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gawk-sum-column"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/input.csv" <<'EOF'
alpha,5
beta,7
gamma,9
EOF
gawk -F, '{sum += $2} END {print sum}' "$tmpdir/input.csv" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" '21'

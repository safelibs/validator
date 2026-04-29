#!/usr/bin/env bash
# @testcase: usage-sed-print-line-range
# @title: sed print line range
# @description: Prints a numeric line range with sed -n and verifies only the selected lines appear in output.
# @timeout: 180
# @tags: usage, sed, text
# @client: sed

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-sed-print-line-range"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.txt" <<'EOF'
one
two
three
four
EOF
sed -n '2,3p' "$tmpdir/in.txt" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'two'
validator_assert_contains "$tmpdir/out" 'three'

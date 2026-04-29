#!/usr/bin/env bash
# @testcase: usage-coreutils-cut-field
# @title: coreutils cut field
# @description: Extracts a CSV column with cut and verifies the selected field values are emitted.
# @timeout: 180
# @tags: usage, coreutils, text
# @client: coreutils

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-coreutils-cut-field"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/input.csv" <<'EOF'
name,score
alpha,42
EOF
cut -d, -f2 "$tmpdir/input.csv" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'score'
validator_assert_contains "$tmpdir/out" '42'

#!/usr/bin/env bash
# @testcase: usage-grep-line-number
# @title: grep line number
# @description: Searches text with grep -n and verifies the matched line number prefix in the output.
# @timeout: 180
# @tags: usage, grep, text
# @client: grep

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-grep-line-number"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/input.txt" <<'EOF'
alpha
beta
gamma
EOF
grep -n 'beta' "$tmpdir/input.txt" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" '2:beta'

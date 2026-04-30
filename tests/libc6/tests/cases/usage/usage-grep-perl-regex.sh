#!/usr/bin/env bash
# @testcase: usage-grep-perl-regex
# @title: grep perl-compatible regex lookahead
# @description: Uses grep -P with a positive lookahead to extract identifiers preceding an equals sign and verifies the match list.
# @timeout: 180
# @tags: usage, grep, regex
# @client: grep

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-grep-perl-regex"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.txt" <<'EOF'
alpha=1
beta=2
gamma_no_value
delta=4
EOF

grep -Po '^\w+(?==)' "$tmpdir/in.txt" >"$tmpdir/out"

validator_assert_contains "$tmpdir/out" 'alpha'
validator_assert_contains "$tmpdir/out" 'beta'
validator_assert_contains "$tmpdir/out" 'delta'
if grep -q 'gamma_no_value' "$tmpdir/out"; then
  printf 'gamma_no_value should not appear in lookahead match output\n' >&2
  exit 1
fi

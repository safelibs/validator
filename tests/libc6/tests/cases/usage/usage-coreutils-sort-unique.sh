#!/usr/bin/env bash
# @testcase: usage-coreutils-sort-unique
# @title: coreutils sort unique
# @description: Sorts duplicated lines with sort -u and verifies the unique output rows remain.
# @timeout: 180
# @tags: usage, coreutils, text
# @client: coreutils

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-coreutils-sort-unique"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/input.txt" <<'EOF'
beta
alpha
beta
EOF
sort -u "$tmpdir/input.txt" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'alpha'
validator_assert_contains "$tmpdir/out" 'beta'

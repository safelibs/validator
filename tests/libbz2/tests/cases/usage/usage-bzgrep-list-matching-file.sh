#!/usr/bin/env bash
# @testcase: usage-bzgrep-list-matching-file
# @title: bzgrep list matching file
# @description: Searches compressed text with bzgrep -l and verifies the matching compressed filename is emitted.
# @timeout: 180
# @tags: usage, bzip2, text
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzgrep-list-matching-file"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/input.txt" <<'EOF'
alpha
beta
gamma
EOF
bzip2 -zk "$tmpdir/input.txt"
bzgrep -l '^beta$' "$tmpdir/input.txt.bz2" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'input.txt.bz2'

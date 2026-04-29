#!/usr/bin/env bash
# @testcase: usage-bzgrep-count-lines
# @title: bzgrep count lines
# @description: Counts matching lines in compressed text with bzgrep -c and verifies the reported match total.
# @timeout: 180
# @tags: usage, bzip2, text
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzgrep-count-lines"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/input.txt" <<'EOF'
beta
alpha
beta
EOF
bzip2 -zk "$tmpdir/input.txt"
bzgrep -c 'beta' "$tmpdir/input.txt.bz2" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" '2'

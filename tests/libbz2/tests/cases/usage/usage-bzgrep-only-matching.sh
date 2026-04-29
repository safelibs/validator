#!/usr/bin/env bash
# @testcase: usage-bzgrep-only-matching
# @title: bzgrep only matching
# @description: Searches a compressed text stream with bzgrep -o and verifies the matched token output.
# @timeout: 180
# @tags: usage, bzip2, search
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzgrep-only-matching"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/input.txt" <<'EOF'
alpha beta gamma
EOF
bzip2 -k "$tmpdir/input.txt"
bzgrep -o beta "$tmpdir/input.txt.bz2" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'beta'

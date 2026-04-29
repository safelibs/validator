#!/usr/bin/env bash
# @testcase: usage-bzgrep-word-regexp
# @title: bzgrep word regexp
# @description: Searches a compressed text stream with bzgrep -w and verifies the matched line output.
# @timeout: 180
# @tags: usage, bzip2, search
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzgrep-word-regexp"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/input.txt" <<'EOF'
alpha beta
gamma
EOF
bzip2 -k "$tmpdir/input.txt"
bzgrep -w beta "$tmpdir/input.txt.bz2" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'alpha beta'

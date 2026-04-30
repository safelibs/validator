#!/usr/bin/env bash
# @testcase: usage-grep-fixed-whole-line
# @title: grep fixed-string whole-line match
# @description: Uses grep -F -x to match exact whole lines literally and confirms partial matches are excluded.
# @timeout: 180
# @tags: usage, grep, regex
# @client: grep

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-grep-fixed-whole-line"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in" <<'EOF'
alpha
alpha-beta
alpha
gamma
EOF

grep -F -x 'alpha' "$tmpdir/in" >"$tmpdir/out"

count=$(wc -l <"$tmpdir/out")
test "$count" -eq 2

# Ensure partial-match line was excluded.
! grep -Fq 'alpha-beta' "$tmpdir/out"

#!/usr/bin/env bash
# @testcase: usage-coreutils-cut-multi-field
# @title: coreutils cut multi-field colon delimiter
# @description: Selects fields 1 and 3 from a colon-delimited record with cut -d: -f1,3 and verifies exact line count and content.
# @timeout: 180
# @tags: usage, coreutils, text
# @client: coreutils

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-coreutils-cut-multi-field"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.txt" <<'EOF'
alpha:1:101:active
beta:2:202:active
gamma:3:303:idle
EOF

cut -d: -f1,3 "$tmpdir/in.txt" >"$tmpdir/out"

test "$(wc -l <"$tmpdir/out")" -eq 3
grep -Fxq 'alpha:101' "$tmpdir/out"
grep -Fxq 'beta:202' "$tmpdir/out"
grep -Fxq 'gamma:303' "$tmpdir/out"
! grep -q 'active' "$tmpdir/out"
! grep -q 'idle' "$tmpdir/out"

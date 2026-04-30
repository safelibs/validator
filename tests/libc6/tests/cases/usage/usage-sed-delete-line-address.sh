#!/usr/bin/env bash
# @testcase: usage-sed-delete-line-address
# @title: sed deletes a specific line by address
# @description: Uses sed '2 d' to drop the second line of a fixed input and verifies the surviving line count and exact content order.
# @timeout: 120
# @tags: usage, sed, text
# @client: sed

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-sed-delete-line-address"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.txt" <<'EOF'
keep-1
drop-me
keep-3
keep-4
EOF

sed '2 d' "$tmpdir/in.txt" >"$tmpdir/out"

test "$(wc -l <"$tmpdir/out")" -eq 3
! grep -q 'drop-me' "$tmpdir/out"
grep -Fxq 'keep-1' "$tmpdir/out"
grep -Fxq 'keep-3' "$tmpdir/out"
grep -Fxq 'keep-4' "$tmpdir/out"

# Order is preserved.
test "$(sed -n '1p' "$tmpdir/out")" = 'keep-1'
test "$(sed -n '2p' "$tmpdir/out")" = 'keep-3'
test "$(sed -n '3p' "$tmpdir/out")" = 'keep-4'

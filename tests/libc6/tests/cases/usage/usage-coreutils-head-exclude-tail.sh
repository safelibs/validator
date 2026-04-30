#!/usr/bin/env bash
# @testcase: usage-coreutils-head-exclude-tail
# @title: coreutils head -n -K excludes trailing lines
# @description: Uses head -n -2 to print all but the last two lines of a fixed input and verifies the surviving line count and contents.
# @timeout: 120
# @tags: usage, coreutils, text
# @client: coreutils

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-coreutils-head-exclude-tail"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.txt" <<'EOF'
line-1
line-2
line-3
line-4
line-5
EOF

head -n -2 "$tmpdir/in.txt" >"$tmpdir/out"

test "$(wc -l <"$tmpdir/out")" -eq 3
grep -Fxq 'line-1' "$tmpdir/out"
grep -Fxq 'line-2' "$tmpdir/out"
grep -Fxq 'line-3' "$tmpdir/out"
! grep -Fxq 'line-4' "$tmpdir/out"
! grep -Fxq 'line-5' "$tmpdir/out"

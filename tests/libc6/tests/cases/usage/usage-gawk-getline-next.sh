#!/usr/bin/env bash
# @testcase: usage-gawk-getline-next
# @title: gawk getline pairs adjacent lines
# @description: Uses gawk getline to consume the line following each header marker and joins the pair, then verifies the exact joined output.
# @timeout: 180
# @tags: usage, gawk, text
# @client: gawk

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gawk-getline-next"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.txt" <<'EOF'
HEADER
alpha-payload
HEADER
beta-payload
HEADER
gamma-payload
EOF

gawk '/^HEADER$/ { if ((getline next_line) > 0) print "pair:" next_line }' "$tmpdir/in.txt" >"$tmpdir/out"

test "$(wc -l <"$tmpdir/out")" -eq 3
grep -Fxq 'pair:alpha-payload' "$tmpdir/out"
grep -Fxq 'pair:beta-payload' "$tmpdir/out"
grep -Fxq 'pair:gamma-payload' "$tmpdir/out"
! grep -q '^HEADER$' "$tmpdir/out"

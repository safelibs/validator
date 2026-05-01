#!/usr/bin/env bash
# @testcase: usage-coreutils-csplit-pattern
# @title: coreutils csplit splits on regex marker
# @description: Uses csplit to break a file into sections at every occurrence of a marker line and verifies the resulting numbered output files contain the expected payload counts.
# @timeout: 120
# @tags: usage, coreutils, libc
# @client: coreutils

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-coreutils-csplit-pattern"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.txt" <<'EOF'
header
==SECTION==
alpha
beta
==SECTION==
gamma
delta
epsilon
EOF

(cd "$tmpdir" && csplit -s -z -f part- -b '%02d.txt' in.txt '/^==SECTION==$/' '{*}')

ls "$tmpdir"/part-*.txt | sort >"$tmpdir/files"
test "$(wc -l <"$tmpdir/files")" -eq 3

# part 0 holds the header before the first marker.
test "$(cat "$tmpdir/part-00.txt")" = 'header'

# part 1 starts with the marker and contains alpha/beta.
validator_assert_contains "$tmpdir/part-01.txt" '==SECTION=='
validator_assert_contains "$tmpdir/part-01.txt" 'alpha'
validator_assert_contains "$tmpdir/part-01.txt" 'beta'

# part 2 starts with the marker and contains gamma/delta/epsilon.
validator_assert_contains "$tmpdir/part-02.txt" '==SECTION=='
validator_assert_contains "$tmpdir/part-02.txt" 'gamma'
validator_assert_contains "$tmpdir/part-02.txt" 'epsilon'

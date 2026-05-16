#!/usr/bin/env bash
# @testcase: usage-bzip2-r21-bzgrep-a2-after-context-lines
# @title: bzgrep -A 2 prints two trailing context lines after each match
# @description: Compresses a six-line payload and runs bzgrep -A 2 looking for a unique pattern on line 3, then asserts the output contains the match line plus the next two lines verbatim - locking in -A's count semantics specifically (existing batch11 after-context test does not pin output to a numeric line count).
# @timeout: 30
# @tags: usage, bzgrep, after-context, r21
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.txt" <<'EOF'
alpha
bravo
target-line-r21
charlie
delta
echo
EOF

bzip2 "$tmpdir/in.txt"
bzgrep -A 2 'target-line-r21' "$tmpdir/in.txt.bz2" >"$tmpdir/out.txt"

# Count lines in output: 1 match + 2 context = 3 lines
n=$(wc -l <"$tmpdir/out.txt")
[[ "$n" -eq 3 ]] || { printf 'expected 3 lines, got %s\n' "$n" >&2; cat "$tmpdir/out.txt" >&2; exit 1; }

validator_assert_contains "$tmpdir/out.txt" 'target-line-r21'
validator_assert_contains "$tmpdir/out.txt" 'charlie'
validator_assert_contains "$tmpdir/out.txt" 'delta'

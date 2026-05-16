#!/usr/bin/env bash
# @testcase: usage-bzip2-r21-bzgrep-context-flag-symmetric
# @title: bzgrep -C 1 prints one line of leading and trailing context
# @description: Compresses a five-line payload, runs bzgrep -C 1 on a unique middle line, and asserts the captured output contains exactly three lines (prev + match + next) - locking in -C's symmetric context behavior which is distinct from -A / -B alone.
# @timeout: 30
# @tags: usage, bzgrep, context, r21
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.txt" <<'EOF'
one
two
middle-r21
four
five
EOF

bzip2 "$tmpdir/in.txt"
bzgrep -C 1 'middle-r21' "$tmpdir/in.txt.bz2" >"$tmpdir/out.txt"

n=$(wc -l <"$tmpdir/out.txt")
[[ "$n" -eq 3 ]] || { printf 'expected 3 lines, got %s\n' "$n" >&2; cat "$tmpdir/out.txt" >&2; exit 1; }

validator_assert_contains "$tmpdir/out.txt" 'two'
validator_assert_contains "$tmpdir/out.txt" 'middle-r21'
validator_assert_contains "$tmpdir/out.txt" 'four'

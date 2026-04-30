#!/usr/bin/env bash
# @testcase: usage-grep-pattern-file
# @title: grep fixed-string pattern file
# @description: Uses grep -F -f to match a haystack against a file of literal patterns and verifies that only the listed entries are reported.
# @timeout: 180
# @tags: usage, grep, text
# @client: grep

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-grep-pattern-file"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/haystack.txt" <<'EOF'
alpha
beta
gamma
delta
epsilon
zeta
eta
EOF

cat >"$tmpdir/patterns.txt" <<'EOF'
beta
delta
eta
EOF

# -x makes grep match each pattern against the whole line so that "eta"
# does not also match "zeta" (substring), pinning the assertion to an
# exact-line semantics.
grep -F -x -f "$tmpdir/patterns.txt" "$tmpdir/haystack.txt" >"$tmpdir/out"

expected=$(printf 'beta\ndelta\neta\n')
actual=$(cat "$tmpdir/out")
if [[ "$actual" != "$expected" ]]; then
  printf 'grep -F -f output mismatch:\n%s\n' "$actual" >&2
  exit 1
fi

line_count=$(wc -l <"$tmpdir/out")
if (( line_count != 3 )); then
  printf 'expected 3 matched lines, got %s\n' "$line_count" >&2
  exit 1
fi

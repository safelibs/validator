#!/usr/bin/env bash
# @testcase: usage-sed-address-range-substitute
# @title: sed address range substitute
# @description: Applies a sed substitution only to lines 2 through 4 with an address range and verifies that lines outside the range are untouched.
# @timeout: 180
# @tags: usage, sed, text
# @client: sed

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-sed-address-range-substitute"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.txt" <<'EOF'
foo line 1
foo line 2
foo line 3
foo line 4
foo line 5
EOF

sed '2,4 s/foo/BAR/' "$tmpdir/in.txt" >"$tmpdir/out"

expected=$(cat <<'EOF'
foo line 1
BAR line 2
BAR line 3
BAR line 4
foo line 5
EOF
)
actual=$(cat "$tmpdir/out")
if [[ "$actual" != "$expected" ]]; then
  printf 'sed range substitute mismatch:\n%s\n' "$actual" >&2
  exit 1
fi

bar_count=$(grep -c '^BAR ' "$tmpdir/out")
foo_count=$(grep -c '^foo ' "$tmpdir/out")
if (( bar_count != 3 )); then
  printf 'expected 3 BAR lines, got %s\n' "$bar_count" >&2
  exit 1
fi
if (( foo_count != 2 )); then
  printf 'expected 2 untouched foo lines, got %s\n' "$foo_count" >&2
  exit 1
fi

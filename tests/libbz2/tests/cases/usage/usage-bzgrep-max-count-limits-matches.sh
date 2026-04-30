#!/usr/bin/env bash
# @testcase: usage-bzgrep-max-count-limits-matches
# @title: bzgrep -m 2 caps match count at two
# @description: Searches a compressed file containing five matching lines with bzgrep -m 2 and verifies only the first two matches are emitted.
# @timeout: 180
# @tags: usage, bzgrep, max-count
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzgrep-max-count-limits-matches"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.txt" <<'EOF'
needle one
filler a
needle two
filler b
needle three
filler c
needle four
filler d
needle five
EOF

bzip2 -zk "$tmpdir/in.txt"

bzgrep -m 2 needle "$tmpdir/in.txt.bz2" >"$tmpdir/out"
line_count=$(wc -l <"$tmpdir/out")
[[ "$line_count" -eq 2 ]] || {
  printf 'expected 2 matches, got %s\n' "$line_count" >&2
  sed -n '1,20p' "$tmpdir/out" >&2
  exit 1
}

validator_assert_contains "$tmpdir/out" 'needle one'
validator_assert_contains "$tmpdir/out" 'needle two'

# The third and later matches must not appear.
if grep -Fq 'needle three' "$tmpdir/out"; then
  printf 'bzgrep -m 2 leaked the third match\n' >&2
  exit 1
fi

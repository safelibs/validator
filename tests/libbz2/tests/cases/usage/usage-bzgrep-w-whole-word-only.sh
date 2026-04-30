#!/usr/bin/env bash
# @testcase: usage-bzgrep-w-whole-word-only
# @title: bzgrep -w matches whole words and rejects substrings
# @description: Searches a compressed file containing both "cat" as a standalone word and "cat" inside larger words (catalog, scatter, concatenate) using bzgrep -w, and verifies only the whole-word lines are emitted while substring lines are excluded.
# @timeout: 180
# @tags: usage, bzgrep, word-regexp
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.txt" <<'EOF'
the cat sat on a mat
catalog of items
let us scatter the seeds
concatenate strings together
a cat and a dog
not a feline at all
EOF

bzip2 -c "$tmpdir/in.txt" >"$tmpdir/in.txt.bz2"

# Run bzgrep -w; whole-word semantics must filter substring matches.
bzgrep -w cat "$tmpdir/in.txt.bz2" >"$tmpdir/out"

# Whole-word lines must be present.
validator_assert_contains "$tmpdir/out" 'the cat sat on a mat'
validator_assert_contains "$tmpdir/out" 'a cat and a dog'

# Substring-only lines must be absent.
for forbidden in 'catalog of items' 'let us scatter the seeds' 'concatenate strings together'; do
  if grep -Fq -- "$forbidden" "$tmpdir/out"; then
    printf 'substring leaked into whole-word output: %s\n' "$forbidden" >&2
    sed -n '1,40p' "$tmpdir/out" >&2
    exit 1
  fi
done

# Exactly two whole-word matches.
match_count=$(wc -l <"$tmpdir/out")
[[ "$match_count" -eq 2 ]] || {
  printf 'expected 2 whole-word matches, got %s\n' "$match_count" >&2
  sed -n '1,40p' "$tmpdir/out" >&2
  exit 1
}

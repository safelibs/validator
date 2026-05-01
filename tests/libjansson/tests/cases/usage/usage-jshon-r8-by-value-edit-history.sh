#!/usr/bin/env bash
# @testcase: usage-jshon-r8-by-value-edit-history
# @title: jshon -V makes intermediate edits non-propagating without explicit re-insertion
# @description: Demonstrates the documented by-reference vs by-value distinction: without -V the chain -e c -n 7 -i d -p mutates the inner object so c.d becomes 7, while with -V the same chain leaves c.d unchanged at the original 5 because the popped intermediate is not re-inserted, and explicitly re-inserting with -i c under -V finally propagates the change.
# @timeout: 120
# @tags: usage, json, jshon
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-r8-by-value-edit-history"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

json='{"a":1,"c":{"d":5,"e":9}}'

# By-reference (default): edit reaches the root.
printf '%s' "$json" | jshon -e c -n 7 -i d -p >"$tmpdir/byref.json"
jshon -F "$tmpdir/byref.json" -e c -e d -u >"$tmpdir/byref-d"
grep -Fxq -- '7' "$tmpdir/byref-d" || {
  printf 'expected c.d=7 by reference, got:\n' >&2
  cat "$tmpdir/byref-d" >&2
  exit 1
}

# By-value, popping without re-insert: edit is lost.
printf '%s' "$json" | jshon -V -e c -n 7 -i d -p >"$tmpdir/byval-pop.json"
jshon -F "$tmpdir/byval-pop.json" -e c -e d -u >"$tmpdir/byval-pop-d"
grep -Fxq -- '5' "$tmpdir/byval-pop-d" || {
  printf 'expected c.d=5 by value with bare pop, got:\n' >&2
  cat "$tmpdir/byval-pop-d" >&2
  exit 1
}

# By-value with explicit re-insertion of the modified subtree at c.
printf '%s' "$json" | jshon -V -e c -n 7 -i d -i c >"$tmpdir/byval-re.json"
jshon -F "$tmpdir/byval-re.json" -e c -e d -u >"$tmpdir/byval-re-d"
grep -Fxq -- '7' "$tmpdir/byval-re-d" || {
  printf 'expected c.d=7 with -V and explicit -i c re-insert, got:\n' >&2
  cat "$tmpdir/byval-re-d" >&2
  exit 1
}

# Sibling key e is preserved in all three documents.
for f in byref.json byval-pop.json byval-re.json; do
  jshon -F "$tmpdir/$f" -e c -e e -u >"$tmpdir/$f.e"
  grep -Fxq -- '9' "$tmpdir/$f.e" || {
    printf 'expected sibling c.e=9 in %s, got:\n' "$f" >&2
    cat "$tmpdir/$f.e" >&2
    exit 1
  }
done

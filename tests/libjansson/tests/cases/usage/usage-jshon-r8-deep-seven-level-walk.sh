#!/usr/bin/env bash
# @testcase: usage-jshon-r8-deep-seven-level-walk
# @title: jshon walks seven nested object levels and unwinds with chained -p
# @description: Drills through seven nested object levels with successive -e calls to fetch the leaf string at l1.l2.l3.l4.l5.l6.l7, then re-runs the descent and pops back four times with chained -p to confirm the navigator lands on level l3 whose only key is l4, exercising deep navigation and stack-unwind balance.
# @timeout: 120
# @tags: usage, json, jshon
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-r8-deep-seven-level-walk"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

json='{"l1":{"l2":{"l3":{"l4":{"l5":{"l6":{"l7":"deep-leaf"}}}}}}}'

# Forward descent reaches the leaf string.
printf '%s' "$json" | jshon -e l1 -e l2 -e l3 -e l4 -e l5 -e l6 -e l7 -u >"$tmpdir/leaf"
grep -Fxq -- 'deep-leaf' "$tmpdir/leaf" || {
  printf 'expected deep-leaf at level seven, got:\n' >&2
  cat "$tmpdir/leaf" >&2
  exit 1
}

# Type at each forward step is object until we reach the string.
printf '%s' "$json" | jshon -e l1 -e l2 -e l3 -e l4 -e l5 -e l6 -t >"$tmpdir/t6"
grep -Fxq -- 'object' "$tmpdir/t6" || {
  printf 'expected object at l6, got:\n' >&2
  cat "$tmpdir/t6" >&2
  exit 1
}
printf '%s' "$json" | jshon -e l1 -e l2 -e l3 -e l4 -e l5 -e l6 -e l7 -t >"$tmpdir/t7"
grep -Fxq -- 'string' "$tmpdir/t7" || {
  printf 'expected string at l7, got:\n' >&2
  cat "$tmpdir/t7" >&2
  exit 1
}

# Descend to l7 then unwind four pops to land on l3 (which has key l4).
printf '%s' "$json" | jshon -e l1 -e l2 -e l3 -e l4 -e l5 -e l6 -e l7 -p -p -p -p -k >"$tmpdir/k3"
grep -Fxq -- 'l4' "$tmpdir/k3" || {
  printf 'expected key l4 after four pops from l7, got:\n' >&2
  cat "$tmpdir/k3" >&2
  exit 1
}
count=$(wc -l <"$tmpdir/k3")
if [[ "$count" -ne 1 ]]; then
  printf 'expected exactly one key at l3 after pops, got %s:\n' "$count" >&2
  cat "$tmpdir/k3" >&2
  exit 1
fi

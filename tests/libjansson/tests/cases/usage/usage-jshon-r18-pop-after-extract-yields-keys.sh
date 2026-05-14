#!/usr/bin/env bash
# @testcase: usage-jshon-r18-pop-after-extract-yields-keys
# @title: jshon -e child -p -k after extract+pop yields the parent object keys
# @description: Pipes {"parent":{"child":42},"sibling":"x"} through jshon -e parent -e child -p -p -k and asserts the captured output contains exactly the two parent-level keys "parent" and "sibling", exercising libjansson's parent-walk via -p after a chained -e descent.
# @timeout: 30
# @tags: usage, json, cli, pop, parent, keys, r18
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf '{"parent":{"child":42},"sibling":"x"}' \
  | jshon -e parent -e child -p -p -k >"$tmpdir/out"
count=$(wc -l <"$tmpdir/out")
if [[ "$count" -ne 2 ]]; then
  printf 'expected 2 parent-level keys, got %s\n' "$count" >&2
  cat "$tmpdir/out" >&2
  exit 1
fi
for key in parent sibling; do
  if ! LC_ALL=C grep -Fxq "$key" "$tmpdir/out"; then
    printf 'missing parent-level key %s\n' "$key" >&2
    cat "$tmpdir/out" >&2
    exit 1
  fi
done

#!/usr/bin/env bash
# @testcase: usage-jshon-r7-delete-then-reinsert-key
# @title: jshon delete a key and re-insert with new value
# @description: Deletes an existing object key with -d, pushes a new string with -s, re-inserts it under the same key name with -i, and verifies the final object still has the original three keys but the targeted key now carries the replacement value.
# @timeout: 120
# @tags: usage, json, jshon
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-r7-delete-then-reinsert-key"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

json='{"a":"old","b":2,"c":3}'

# Delete "a" then reinsert with replacement value.
result=$(printf '%s' "$json" | jshon -d a -s "new" -i a)
printf '%s' "$result" >"$tmpdir/r.json"

# Length stays at 3.
jshon -F "$tmpdir/r.json" -l >"$tmpdir/len"
grep -Fxq -- '3' "$tmpdir/len" || {
  printf 'expected length 3 after delete+reinsert, got:\n' >&2
  cat "$tmpdir/len" >&2
  exit 1
}

# Key "a" now has the new string value.
jshon -F "$tmpdir/r.json" -e a -u >"$tmpdir/va"
if ! grep -Fxq -- 'new' "$tmpdir/va"; then
  printf 'expected new at key a, got:\n' >&2
  cat "$tmpdir/va" >&2
  exit 1
fi

# Type at key "a" is string (was string before, but reinserted with -s).
jshon -F "$tmpdir/r.json" -e a -t >"$tmpdir/ta"
grep -Fxq -- 'string' "$tmpdir/ta" || {
  printf 'expected string type at key a, got:\n' >&2
  cat "$tmpdir/ta" >&2
  exit 1
}

# Other keys unchanged.
jshon -F "$tmpdir/r.json" -e b -u >"$tmpdir/vb"
grep -Fxq -- '2' "$tmpdir/vb" || { printf 'expected 2 at b, got:\n' >&2; cat "$tmpdir/vb" >&2; exit 1; }
jshon -F "$tmpdir/r.json" -e c -u >"$tmpdir/vc"
grep -Fxq -- '3' "$tmpdir/vc" || { printf 'expected 3 at c, got:\n' >&2; cat "$tmpdir/vc" >&2; exit 1; }

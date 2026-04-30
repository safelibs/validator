#!/usr/bin/env bash
# @testcase: usage-jshon-r3-numeric-string-keys
# @title: jshon -e on object keys that are numeric strings
# @description: Builds an object whose keys are the string forms of integers ("1","2","3") and verifies jshon -e treats them as ordinary string keys, not array indices, returning the associated values via -u.
# @timeout: 120
# @tags: usage, json, jshon
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-r3-numeric-string-keys"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Top-level value is an OBJECT, not an array. The keys happen to be the
# strings "1", "2", "3".
json='{"1":"one","2":"two","3":"three"}'
printf '%s' "$json" >"$tmpdir/input.json"

# Type must be object (not array).
jshon -F "$tmpdir/input.json" -t >"$tmpdir/type"
grep -Fxq -- 'object' "$tmpdir/type" || {
  printf 'expected object root, got:\n' >&2
  cat "$tmpdir/type" >&2
  exit 1
}

# Each numeric-string key must extract as the spelled-out value.
declare -A expected=( ["1"]=one ["2"]=two ["3"]=three )
for k in 1 2 3; do
  jshon -F "$tmpdir/input.json" -e "$k" -u >"$tmpdir/v-$k"
  if ! grep -Fxq -- "${expected[$k]}" "$tmpdir/v-$k"; then
    printf 'expected %s at key "%s", got:\n' "${expected[$k]}" "$k" >&2
    cat "$tmpdir/v-$k" >&2
    exit 1
  fi
done

# -k must list exactly three keys.
jshon -F "$tmpdir/input.json" -k >"$tmpdir/keys"
count=$(wc -l <"$tmpdir/keys")
if [[ "$count" -ne 3 ]]; then
  printf 'expected 3 keys, got %s:\n' "$count" >&2
  cat "$tmpdir/keys" >&2
  exit 1
fi

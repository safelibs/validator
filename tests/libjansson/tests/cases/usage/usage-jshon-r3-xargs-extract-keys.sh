#!/usr/bin/env bash
# @testcase: usage-jshon-r3-xargs-extract-keys
# @title: jshon -k piped through xargs back into jshon -e
# @description: Lists object keys with jshon -k, pipes them through xargs into a fresh jshon -e invocation per key, and confirms each per-key extraction returns the expected unstringed value.
# @timeout: 180
# @tags: usage, json, jshon
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-r3-xargs-extract-keys"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

json='{"alpha":"A","beta":"B","gamma":"C","delta":"D"}'
printf '%s' "$json" >"$tmpdir/input.json"

# Get the list of keys via jshon -k.
jshon -F "$tmpdir/input.json" -k >"$tmpdir/keys"

key_count=$(wc -l <"$tmpdir/keys")
if [[ "$key_count" -ne 4 ]]; then
  printf 'expected 4 keys, got %s:\n' "$key_count" >&2
  cat "$tmpdir/keys" >&2
  exit 1
fi

# For each key, re-run jshon -e <key> -u via xargs and accumulate output.
xargs -I {} -a "$tmpdir/keys" \
  jshon -F "$tmpdir/input.json" -e {} -u >"$tmpdir/values"

value_count=$(wc -l <"$tmpdir/values")
if [[ "$value_count" -ne 4 ]]; then
  printf 'expected 4 unstringed values, got %s:\n' "$value_count" >&2
  cat "$tmpdir/values" >&2
  exit 1
fi

for v in A B C D; do
  if ! grep -Fxq -- "$v" "$tmpdir/values"; then
    printf 'expected value %s among xargs-extracted values, got:\n' "$v" >&2
    cat "$tmpdir/values" >&2
    exit 1
  fi
done

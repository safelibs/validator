#!/usr/bin/env bash
# @testcase: usage-jshon-r3-whitespace-key
# @title: jshon -e on an object key containing whitespace
# @description: Defines an object with a key that contains a literal space and asserts jshon -e accepts the key as a single argument and returns the matching value.
# @timeout: 120
# @tags: usage, json, jshon
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-r3-whitespace-key"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Key is the four-character string: f i r s t (space) name
json='{"first name":"Ada","last name":"Lovelace"}'
printf '%s' "$json" >"$tmpdir/input.json"

# Quoted argument so the space stays inside the single -e argument.
jshon -F "$tmpdir/input.json" -e 'first name' -u >"$tmpdir/first"
if ! grep -Fxq -- 'Ada' "$tmpdir/first"; then
  printf 'expected Ada at "first name", got:\n' >&2
  cat "$tmpdir/first" >&2
  exit 1
fi

jshon -F "$tmpdir/input.json" -e 'last name' -u >"$tmpdir/last"
if ! grep -Fxq -- 'Lovelace' "$tmpdir/last"; then
  printf 'expected Lovelace at "last name", got:\n' >&2
  cat "$tmpdir/last" >&2
  exit 1
fi

# The keys listing must contain both whitespace-bearing keys verbatim.
jshon -F "$tmpdir/input.json" -k >"$tmpdir/keys"
for k in 'first name' 'last name'; do
  if ! grep -Fxq -- "$k" "$tmpdir/keys"; then
    printf 'expected key "%s" in -k output, got:\n' "$k" >&2
    cat "$tmpdir/keys" >&2
    exit 1
  fi
done

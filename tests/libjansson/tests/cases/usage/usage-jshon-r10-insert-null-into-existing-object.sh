#!/usr/bin/env bash
# @testcase: usage-jshon-r10-insert-null-into-existing-object
# @title: jshon -n null -i adds a null-valued key to an existing object
# @description: Inserts a JSON null using -n null -i into an object that already has one key and verifies the resulting object has both keys, with the new one typed as null.
# @timeout: 60
# @tags: usage, json, cli
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf '{"keep":"yes"}' | jshon -n null -i added >"$tmpdir/built.json"

jshon -F "$tmpdir/built.json" -l >"$tmpdir/length"
length=$(<"$tmpdir/length")
if [[ "$length" != "2" ]]; then
  printf 'expected length 2 after inserting null key, got: %q\n' "$length" >&2
  cat "$tmpdir/built.json" >&2
  exit 1
fi

jshon -F "$tmpdir/built.json" -e added -t >"$tmpdir/type"
validator_assert_contains "$tmpdir/type" 'null'

jshon -F "$tmpdir/built.json" -e keep -u >"$tmpdir/keep"
validator_assert_contains "$tmpdir/keep" 'yes'

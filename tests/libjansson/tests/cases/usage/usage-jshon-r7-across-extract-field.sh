#!/usr/bin/env bash
# @testcase: usage-jshon-r7-across-extract-field
# @title: jshon -a -e id -u plucks one field from each record
# @description: Applies the across operator to an array of three uniform record objects, extracts the id field from each, unstrings it, and verifies the three id strings emerge in input order on three separate lines.
# @timeout: 120
# @tags: usage, json, jshon
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-r7-across-extract-field"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

json='[{"id":"a1","v":10},{"id":"b2","v":20},{"id":"c3","v":30}]'

printf '%s' "$json" | jshon -a -e id -u >"$tmpdir/ids"

count=$(wc -l <"$tmpdir/ids")
if [[ "$count" -ne 3 ]]; then
  printf 'expected 3 id lines, got %s:\n' "$count" >&2
  cat "$tmpdir/ids" >&2
  exit 1
fi

expected=$(printf 'a1\nb2\nc3\n')
if [[ "$(cat "$tmpdir/ids")" != "$expected" ]]; then
  printf 'unexpected id sequence, got:\n' >&2
  cat "$tmpdir/ids" >&2
  exit 1
fi

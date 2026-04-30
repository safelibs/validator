#!/usr/bin/env bash
# @testcase: usage-jshon-r4-data-array-id-extract
# @title: jshon -e walks object then array index then field
# @description: Builds {"data":[{"id":1},{"id":2}]} and verifies jshon -e data -e 1 -e id -u returns 2 while -e data -e 0 -e id -u returns 1, exercising mixed object/array descent at varying indices.
# @timeout: 120
# @tags: usage, json, jshon
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-r4-data-array-id-extract"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

json='{"data":[{"id":1},{"id":2}]}'

printf '%s' "$json" | jshon -e data -e 1 -e id -u >"$tmpdir/second"
if ! grep -Fxq -- '2' "$tmpdir/second"; then
  printf 'expected id 2 at data[1], got:\n' >&2
  cat "$tmpdir/second" >&2
  exit 1
fi

printf '%s' "$json" | jshon -e data -e 0 -e id -u >"$tmpdir/first"
if ! grep -Fxq -- '1' "$tmpdir/first"; then
  printf 'expected id 1 at data[0], got:\n' >&2
  cat "$tmpdir/first" >&2
  exit 1
fi

# Top-level type must be object; data must be array.
printf '%s' "$json" | jshon -t >"$tmpdir/root_t"
grep -Fxq -- 'object' "$tmpdir/root_t" || {
  printf 'expected object at root, got:\n' >&2
  cat "$tmpdir/root_t" >&2
  exit 1
}

printf '%s' "$json" | jshon -e data -t >"$tmpdir/data_t"
grep -Fxq -- 'array' "$tmpdir/data_t" || {
  printf 'expected array at data, got:\n' >&2
  cat "$tmpdir/data_t" >&2
  exit 1
}

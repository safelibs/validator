#!/usr/bin/env bash
# @testcase: usage-jshon-r5-redirect-to-file-and-reparse
# @title: jshon output redirected to file then re-parsed
# @description: Captures jshon's emitted JSON sub-document via shell redirection into a file, then re-loads that file with jshon -F and verifies the round-tripped document still answers structural queries (type, length, key extract) consistently.
# @timeout: 120
# @tags: usage, json, jshon
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-r5-redirect-to-file-and-reparse"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

json='{"root":{"name":"alpha","scores":[10,20,30],"active":true}}'

# Emit the inner object via a single jshon invocation, capture to file via shell redirection.
printf '%s' "$json" | jshon -e root >"$tmpdir/inner.json"

# File must be non-empty.
test -s "$tmpdir/inner.json"

# Re-parse with -F and assert the inner object's type.
jshon -F "$tmpdir/inner.json" -t >"$tmpdir/type"
if ! grep -Fxq -- 'object' "$tmpdir/type"; then
  printf 'expected object type after redirect+reparse, got:\n' >&2
  cat "$tmpdir/type" >&2
  exit 1
fi

# Three keys survive the round trip.
jshon -F "$tmpdir/inner.json" -l >"$tmpdir/len"
if ! grep -Fxq -- '3' "$tmpdir/len"; then
  printf 'expected length 3 after redirect+reparse, got:\n' >&2
  cat "$tmpdir/len" >&2
  exit 1
fi

# Leaf string is recoverable.
jshon -F "$tmpdir/inner.json" -e name -u >"$tmpdir/name"
if ! grep -Fxq -- 'alpha' "$tmpdir/name"; then
  printf 'expected name alpha after redirect+reparse, got:\n' >&2
  cat "$tmpdir/name" >&2
  exit 1
fi

# Nested array length stays at 3.
jshon -F "$tmpdir/inner.json" -e scores -l >"$tmpdir/scoreslen"
if ! grep -Fxq -- '3' "$tmpdir/scoreslen"; then
  printf 'expected scores length 3 after redirect+reparse, got:\n' >&2
  cat "$tmpdir/scoreslen" >&2
  exit 1
fi

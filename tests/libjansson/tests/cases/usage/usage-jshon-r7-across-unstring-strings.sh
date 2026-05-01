#!/usr/bin/env bash
# @testcase: usage-jshon-r7-across-unstring-strings
# @title: jshon -a -u unstrings every array element
# @description: Streams a homogeneous string array through jshon -a -u and verifies the output contains exactly the four raw (unquoted) strings, one per line, in the original array order, exercising the across operator combined with unstring rather than per-index extracts.
# @timeout: 120
# @tags: usage, json, jshon
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-r7-across-unstring-strings"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

json='["alpha","beta","gamma","delta"]'

printf '%s' "$json" | jshon -a -u >"$tmpdir/out"

count=$(wc -l <"$tmpdir/out")
if [[ "$count" -ne 4 ]]; then
  printf 'expected 4 unstringed lines, got %s:\n' "$count" >&2
  cat "$tmpdir/out" >&2
  exit 1
fi

expected=$(printf 'alpha\nbeta\ngamma\ndelta\n')
if [[ "$(cat "$tmpdir/out")" != "$expected" ]]; then
  printf 'unexpected -a -u sequence, got:\n' >&2
  cat "$tmpdir/out" >&2
  exit 1
fi

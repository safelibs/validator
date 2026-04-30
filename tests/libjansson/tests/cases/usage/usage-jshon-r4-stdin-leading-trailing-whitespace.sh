#!/usr/bin/env bash
# @testcase: usage-jshon-r4-stdin-leading-trailing-whitespace
# @title: jshon tolerates leading and trailing whitespace on stdin
# @description: Pipes a JSON object surrounded by leading newlines/spaces and trailing whitespace into jshon, and verifies the parser still extracts the nested value identically to the whitespace-stripped version.
# @timeout: 120
# @tags: usage, json, jshon
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-r4-stdin-leading-trailing-whitespace"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

inner='{"name":"demo","count":7}'

# Whitespace-padded input.
{ printf '\n\n   \t'; printf '%s' "$inner"; printf '   \n\t \n'; } \
  | jshon -e count -u >"$tmpdir/padded"

# Whitespace-clean input.
printf '%s' "$inner" | jshon -e count -u >"$tmpdir/clean"

if ! diff -u "$tmpdir/clean" "$tmpdir/padded" >"$tmpdir/diff"; then
  printf 'padded vs clean output differs:\n' >&2
  cat "$tmpdir/diff" >&2
  exit 1
fi

if ! grep -Fxq -- '7' "$tmpdir/padded"; then
  printf 'expected count 7 from padded input, got:\n' >&2
  cat "$tmpdir/padded" >&2
  exit 1
fi

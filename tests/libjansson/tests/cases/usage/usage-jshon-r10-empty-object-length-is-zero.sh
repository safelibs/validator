#!/usr/bin/env bash
# @testcase: usage-jshon-r10-empty-object-length-is-zero
# @title: jshon -l on an empty object returns 0
# @description: Reads {} and confirms that jshon -l reports the object length as exactly 0, distinct from the empty-array length case.
# @timeout: 60
# @tags: usage, json, cli
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf '{}' | jshon -l >"$tmpdir/out"

actual=$(<"$tmpdir/out")
if [[ "$actual" != "0" ]]; then
  printf 'expected length 0 for empty object, got: %q\n' "$actual" >&2
  exit 1
fi

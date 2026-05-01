#!/usr/bin/env bash
# @testcase: usage-jshon-r8-empty-array-across-noop
# @title: jshon -a maps over an empty top-level array as a silent no-op
# @description: Applies the across operator to a top-level empty array and a nested empty array under a key, verifying the inner action -t produces no output lines and exits zero in both cases, while -k against the empty array still fails as documented because keys is undefined for arrays of any size.
# @timeout: 120
# @tags: usage, json, jshon
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-r8-empty-array-across-noop"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Top-level empty array -- across is a no-op.
printf '[]' | jshon -a -t >"$tmpdir/top-out" 2>"$tmpdir/top-err"
if [[ -s "$tmpdir/top-out" ]]; then
  printf 'expected empty stdout from -a -t on [], got:\n' >&2
  cat "$tmpdir/top-out" >&2
  exit 1
fi
if [[ -s "$tmpdir/top-err" ]]; then
  printf 'expected empty stderr from -a -t on [], got:\n' >&2
  cat "$tmpdir/top-err" >&2
  exit 1
fi

# Nested empty array under a key -- same no-op behavior.
printf '{"items":[]}' | jshon -e items -a -u >"$tmpdir/nested-out" 2>"$tmpdir/nested-err"
if [[ -s "$tmpdir/nested-out" ]]; then
  printf 'expected empty stdout from -e items -a -u on empty array, got:\n' >&2
  cat "$tmpdir/nested-out" >&2
  exit 1
fi

# Length is reported as 0.
printf '[]' | jshon -l >"$tmpdir/len"
grep -Fxq -- '0' "$tmpdir/len" || {
  printf 'expected length 0 for [], got:\n' >&2
  cat "$tmpdir/len" >&2
  exit 1
}

# -k on an array (even empty) is documented to fail; confirm the diagnostic.
set +e
printf '[]' | jshon -k >"$tmpdir/k-out" 2>"$tmpdir/k-err"
rc=$?
set -e
if [[ "$rc" -eq 0 ]]; then
  printf 'expected non-zero exit from jshon -k on [], got %s\n' "$rc" >&2
  exit 1
fi

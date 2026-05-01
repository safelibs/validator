#!/usr/bin/env bash
# @testcase: usage-jshon-r8-continue-missing-key-yields-null
# @title: jshon -C makes missing-key extraction recover with a null on the stack
# @description: Without -C, jshon -e on an absent object key aborts with a non-zero exit; with -C, the same extraction pushes a null onto the edit stack so a following -t reports the literal type label null and the invocation succeeds, demonstrating the documented continue-on-error semantics.
# @timeout: 120
# @tags: usage, json, jshon
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-r8-continue-missing-key-yields-null"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

json='{"present":42}'

# Baseline: without -C, missing key fails.
set +e
printf '%s' "$json" | jshon -e absent -t >"$tmpdir/baseline-out" 2>"$tmpdir/baseline-err"
rc_base=$?
set -e
if [[ "$rc_base" -eq 0 ]]; then
  printf 'expected non-zero exit on missing key without -C, got %s\n' "$rc_base" >&2
  exit 1
fi

# With -C: jshon recovers, pushes null onto stack, prints type "null", exits 0.
printf '%s' "$json" | jshon -C -e absent -t >"$tmpdir/cont-type" 2>"$tmpdir/cont-err"
grep -Fxq -- 'null' "$tmpdir/cont-type" || {
  printf 'expected type null after -C -e absent, got:\n' >&2
  cat "$tmpdir/cont-type" >&2
  exit 1
}

# A present key still extracts normally under -C.
printf '%s' "$json" | jshon -C -e present -u >"$tmpdir/present-val"
grep -Fxq -- '42' "$tmpdir/present-val" || {
  printf 'expected 42 from -C -e present -u, got:\n' >&2
  cat "$tmpdir/present-val" >&2
  exit 1
}

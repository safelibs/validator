#!/usr/bin/env bash
# @testcase: usage-jshon-r8-quiet-suppresses-stderr
# @title: jshon -Q silences error reporting while preserving the failing exit
# @description: Compares jshon -e on a missing key with and without -Q, asserting that the bare invocation writes a non-empty error to stderr while the -Q variant emits nothing on stderr, and that both invocations still exit non-zero so callers can detect the failure without parsing diagnostics.
# @timeout: 120
# @tags: usage, json, jshon
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-r8-quiet-suppresses-stderr"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

json='{"present":1,"other":2}'

# Without -Q: stderr is non-empty and exit is non-zero.
set +e
printf '%s' "$json" | jshon -e absent -u >"$tmpdir/out-noq" 2>"$tmpdir/err-noq"
rc_noq=$?
set -e

if [[ "$rc_noq" -eq 0 ]]; then
  printf 'expected non-zero exit without -Q, got %s\n' "$rc_noq" >&2
  exit 1
fi
if [[ ! -s "$tmpdir/err-noq" ]]; then
  printf 'expected non-empty stderr without -Q\n' >&2
  exit 1
fi

# With -Q: stderr is empty but the exit is still non-zero.
set +e
printf '%s' "$json" | jshon -Q -e absent -u >"$tmpdir/out-q" 2>"$tmpdir/err-q"
rc_q=$?
set -e

if [[ "$rc_q" -eq 0 ]]; then
  printf 'expected non-zero exit with -Q, got %s\n' "$rc_q" >&2
  exit 1
fi
if [[ -s "$tmpdir/err-q" ]]; then
  printf 'expected empty stderr with -Q, got:\n' >&2
  cat "$tmpdir/err-q" >&2
  exit 1
fi

# Sanity: -Q does not break a successful extraction.
printf '%s' "$json" | jshon -Q -e present -u >"$tmpdir/ok" 2>"$tmpdir/ok-err"
grep -Fxq -- '1' "$tmpdir/ok" || {
  printf 'expected 1 from -Q -e present -u, got:\n' >&2
  cat "$tmpdir/ok" >&2
  exit 1
}
if [[ -s "$tmpdir/ok-err" ]]; then
  printf 'expected empty stderr on success with -Q, got:\n' >&2
  cat "$tmpdir/ok-err" >&2
  exit 1
fi

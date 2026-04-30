#!/usr/bin/env bash
# @testcase: usage-bzip2-q-suppresses-suffix-warning
# @title: bzip2 -q suppresses unrecognised-suffix warnings
# @description: Decompresses a bzip2 stream stored under a non-canonical suffix and verifies that bzip2 normally warns "Can't guess original name" on stderr but produces no such warning when -q is supplied, while still producing the correct decompressed output.
# @timeout: 180
# @tags: usage, bzip2, quiet, warnings
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'quiet-flag suffix payload\n' >"$tmpdir/in.txt"
bzip2 -c "$tmpdir/in.txt" >"$tmpdir/in.weird"   # non-.bz2 suffix on purpose

# Baseline: without -q, bzip2 -d emits a "Can't guess original name" warning
# on stderr but still succeeds. Use --keep so the input survives for the
# quiet-mode comparison below.
cp "$tmpdir/in.weird" "$tmpdir/loud.weird"
bzip2 -d --keep "$tmpdir/loud.weird" 2>"$tmpdir/loud.err"
validator_require_file "$tmpdir/loud.weird.out"
cmp "$tmpdir/in.txt" "$tmpdir/loud.weird.out"
# The warning must appear on stderr in the loud (default) invocation.
validator_assert_contains "$tmpdir/loud.err" "Can't guess original name"

# Quiet variant: -q must suppress the warning while still succeeding.
cp "$tmpdir/in.weird" "$tmpdir/quiet.weird"
bzip2 -d -q --keep "$tmpdir/quiet.weird" 2>"$tmpdir/quiet.err"
validator_require_file "$tmpdir/quiet.weird.out"
cmp "$tmpdir/in.txt" "$tmpdir/quiet.weird.out"
[[ ! -s "$tmpdir/quiet.err" ]] || {
  printf 'expected -q to suppress stderr, got:\n' >&2
  cat "$tmpdir/quiet.err" >&2
  exit 1
}

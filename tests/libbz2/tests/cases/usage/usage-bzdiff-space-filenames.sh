#!/usr/bin/env bash
# @testcase: usage-bzdiff-space-filenames
# @title: bzdiff changed-line output
# @description: Exercises bzdiff changed-line output through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzdiff-space-filenames"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

sample_root="$VALIDATOR_SAMPLE_ROOT"

printf 'alpha\n' >"$tmpdir/left.txt"
printf 'beta\n' >"$tmpdir/right.txt"
bzip2 -c "$tmpdir/left.txt" >"$tmpdir/left.txt.bz2"
bzip2 -c "$tmpdir/right.txt" >"$tmpdir/right.txt.bz2"
if bzdiff "$tmpdir/left.txt.bz2" "$tmpdir/right.txt.bz2" >"$tmpdir/out" 2>&1; then
  printf 'bzdiff unexpectedly reported identical content\n' >&2
  exit 1
fi
validator_assert_contains "$tmpdir/out" '< alpha'
validator_assert_contains "$tmpdir/out" '> beta'

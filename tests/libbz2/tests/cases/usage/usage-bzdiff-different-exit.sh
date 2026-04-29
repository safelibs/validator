#!/usr/bin/env bash
# @testcase: usage-bzdiff-different-exit
# @title: bzdiff different files
# @description: Diffs two different compressed files with bzdiff and verifies the command reports a textual difference.
# @timeout: 180
# @tags: usage, compression, cli
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzdiff-different-exit"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'alpha\n' >"$tmpdir/one.txt"
printf 'beta\n' >"$tmpdir/two.txt"
bzip2 -c "$tmpdir/one.txt" >"$tmpdir/one.txt.bz2"
bzip2 -c "$tmpdir/two.txt" >"$tmpdir/two.txt.bz2"
if bzdiff "$tmpdir/one.txt.bz2" "$tmpdir/two.txt.bz2" >"$tmpdir/out" 2>&1; then
  printf 'bzdiff unexpectedly reported identical files\n' >&2
  exit 1
fi
validator_assert_contains "$tmpdir/out" '< alpha'
validator_assert_contains "$tmpdir/out" '> beta'

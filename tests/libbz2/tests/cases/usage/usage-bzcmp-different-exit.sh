#!/usr/bin/env bash
# @testcase: usage-bzcmp-different-exit
# @title: bzcmp different files
# @description: Compares two different compressed files with bzcmp and verifies the command reports a textual difference.
# @timeout: 180
# @tags: usage, compression, cli
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzcmp-different-exit"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'left\n' >"$tmpdir/one.txt"
printf 'right\n' >"$tmpdir/two.txt"
bzip2 -c "$tmpdir/one.txt" >"$tmpdir/one.txt.bz2"
bzip2 -c "$tmpdir/two.txt" >"$tmpdir/two.txt.bz2"
if bzcmp "$tmpdir/one.txt.bz2" "$tmpdir/two.txt.bz2" >"$tmpdir/out" 2>&1; then
  printf 'bzcmp unexpectedly reported identical files\n' >&2
  exit 1
fi
validator_assert_contains "$tmpdir/out" 'differ:'

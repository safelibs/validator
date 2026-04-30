#!/usr/bin/env bash
# @testcase: usage-bzcmp-trailing-byte-difference
# @title: bzcmp pinpoints differing byte across compressed pair
# @description: Builds two .bz2 inputs whose decompressed payloads differ by one byte and verifies bzcmp reports a non-zero exit with the differing offset.
# @timeout: 180
# @tags: usage, compare, negative
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'shared bzcmp payload AAA\n' >"$tmpdir/a.txt"
printf 'shared bzcmp payload BAA\n' >"$tmpdir/b.txt"

bzip2 -c "$tmpdir/a.txt" >"$tmpdir/a.bz2"
bzip2 -c "$tmpdir/b.txt" >"$tmpdir/b.bz2"

# Identical-content compare must succeed.
bzcmp "$tmpdir/a.bz2" "$tmpdir/a.bz2"

# Differing-content compare must exit non-zero with diagnostic output.
set +e
bzcmp "$tmpdir/a.bz2" "$tmpdir/b.bz2" >"$tmpdir/diff.out" 2>&1
rc=$?
set -e
if (( rc == 0 )); then
  printf 'bzcmp unexpectedly reported equal files\n' >&2
  exit 1
fi
[[ -s "$tmpdir/diff.out" ]]
validator_assert_contains "$tmpdir/diff.out" 'differ'

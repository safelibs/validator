#!/usr/bin/env bash
# @testcase: usage-bzip2-r18-bzgrep-v-invert-multifile
# @title: bzgrep -v across two archives emits lines that do not match the pattern
# @description: Builds two bz2-compressed files each with both matching and non-matching lines, runs bzgrep -v with a multi-file invocation, and asserts the output omits the matching lines but contains the non-matching ones from both archives — locking in invert-match across multi-archive iteration.
# @timeout: 60
# @tags: usage, bzgrep, invert, multifile, r18
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'apple\nbanana\ncherry\n' >"$tmpdir/a.txt"
printf 'avocado\nblueberry\ncranberry\n' >"$tmpdir/b.txt"
bzip2 "$tmpdir/a.txt" "$tmpdir/b.txt"

bzgrep -v '^a' "$tmpdir/a.txt.bz2" "$tmpdir/b.txt.bz2" >"$tmpdir/out"

# Should contain the non-matching lines and not the a-prefixed ones.
validator_assert_contains "$tmpdir/out" 'banana'
validator_assert_contains "$tmpdir/out" 'cherry'
validator_assert_contains "$tmpdir/out" 'blueberry'
validator_assert_contains "$tmpdir/out" 'cranberry'
! grep -F 'apple' "$tmpdir/out"
! grep -F 'avocado' "$tmpdir/out"

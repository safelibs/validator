#!/usr/bin/env bash
# @testcase: usage-bzip2-r14-test-three-files-all-pass
# @title: bzip2 -t accepts three valid .bz2 files in one invocation
# @description: Compresses three distinct payloads, runs "bzip2 -t" with all three .bz2 files supplied as positional arguments in one call, and asserts the command exits zero with empty stdout (test mode produces no output on success).
# @timeout: 60
# @tags: usage, bzip2, test, multi-file
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'tt-alpha payload\n' >"$tmpdir/a.txt"
printf 'tt-beta longer payload bytes\n' >"$tmpdir/b.txt"
printf 'tt-gamma final\n' >"$tmpdir/c.txt"

bzip2 "$tmpdir/a.txt" "$tmpdir/b.txt" "$tmpdir/c.txt"

[[ -f "$tmpdir/a.txt.bz2" ]]
[[ -f "$tmpdir/b.txt.bz2" ]]
[[ -f "$tmpdir/c.txt.bz2" ]]

bzip2 -t "$tmpdir/a.txt.bz2" "$tmpdir/b.txt.bz2" "$tmpdir/c.txt.bz2" >"$tmpdir/test.out"
[[ ! -s "$tmpdir/test.out" ]]

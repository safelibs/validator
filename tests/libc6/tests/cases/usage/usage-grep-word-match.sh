#!/usr/bin/env bash
# @testcase: usage-grep-word-match
# @title: grep whole-word match
# @description: Matches a whole-word pattern with grep and verifies partial words are excluded.
# @timeout: 180
# @tags: usage, cli
# @client: grep

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-grep-word-match"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'alpha\nalphabet\nbeta alpha\n' >"$tmpdir/in.txt"
grep -w 'alpha' "$tmpdir/in.txt" >"$tmpdir/out"
grep -Fxq 'alpha' "$tmpdir/out"
grep -Fxq 'beta alpha' "$tmpdir/out"

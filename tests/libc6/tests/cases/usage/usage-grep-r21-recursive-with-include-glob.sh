#!/usr/bin/env bash
# @testcase: usage-grep-r21-recursive-with-include-glob
# @title: grep -r --include="*.log" restricts recursion to files matching the glob
# @description: Builds a directory tree containing a .log file holding a unique token and a .txt file with the same token, runs grep -r --include="*.log" on the directory, and asserts only the .log file's match is reported - locking in --include's filtering interaction with -r recursion (existing include-glob test uses non-recursive grep).
# @timeout: 30
# @tags: usage, grep, recursive, include-glob, r21
# @client: grep

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/sub"
printf 'token-r21\n' >"$tmpdir/sub/a.log"
printf 'token-r21\n' >"$tmpdir/sub/b.txt"

grep -r --include='*.log' 'token-r21' "$tmpdir" >"$tmpdir/out.txt"

n=$(wc -l <"$tmpdir/out.txt")
[[ "$n" -eq 1 ]] || { printf 'expected 1 line, got %s\n' "$n" >&2; cat "$tmpdir/out.txt" >&2; exit 1; }
validator_assert_contains "$tmpdir/out.txt" 'a.log'
grep -F -q 'b.txt' "$tmpdir/out.txt" && { echo 'unexpected .txt match' >&2; exit 1; } || true

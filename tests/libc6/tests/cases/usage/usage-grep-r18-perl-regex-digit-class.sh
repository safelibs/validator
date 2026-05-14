#!/usr/bin/env bash
# @testcase: usage-grep-r18-perl-regex-digit-class
# @title: grep -P matches the perl-compatible \d digit class against a mixed line
# @description: Builds a three-line input where only the middle line contains digits, runs grep -P '\d+' on it, and asserts the output is exactly the digit-bearing line — locking in PCRE-flavored regular expression support in noble's grep build.
# @timeout: 30
# @tags: usage, grep, pcre, digits, r18
# @client: grep

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.txt" <<'TXT'
alpha bravo
target 12345
charlie delta
TXT

grep -P '\d+' "$tmpdir/in.txt" >"$tmpdir/out.txt"
got=$(cat "$tmpdir/out.txt")
want='target 12345'
[[ "$got" == "$want" ]] || {
    printf 'pcre mismatch: want=%q got=%q\n' "$want" "$got" >&2
    exit 1
}

#!/usr/bin/env bash
# @testcase: usage-grep-r11-fixed-string-multiline-pattern
# @title: grep -F with multiline pattern matches any of the literal lines
# @description: Passes a two-line newline-separated literal pattern to grep -F and verifies it matches lines containing either literal exercising grep multi-pattern handling via libc memchr-based scanning.
# @timeout: 60
# @tags: usage, grep, fixed
# @client: grep

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

LC_ALL=C
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'apple\nbanana\ncherry\ndate\n' >"$tmpdir/in.txt"
LC_ALL=C grep -F $'apple\ndate' "$tmpdir/in.txt" >"$tmpdir/got.txt"
LC_ALL=C diff -u <(printf 'apple\ndate\n') "$tmpdir/got.txt"

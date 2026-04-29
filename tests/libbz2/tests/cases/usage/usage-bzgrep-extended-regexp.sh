#!/usr/bin/env bash
# @testcase: usage-bzgrep-extended-regexp
# @title: bzgrep extended regexp alternation
# @description: Searches a compressed text stream with bzgrep -E and verifies both alternation branches produce matching lines.
# @timeout: 180
# @tags: usage, bzip2, search
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzgrep-extended-regexp"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'apple\nbanana\ncherry\n' >"$tmpdir/in.txt"
bzip2 -c "$tmpdir/in.txt" >"$tmpdir/in.txt.bz2"
bzgrep -E 'app|cher' "$tmpdir/in.txt.bz2" >"$tmpdir/out"
grep -Fxq 'apple' "$tmpdir/out"
grep -Fxq 'cherry' "$tmpdir/out"

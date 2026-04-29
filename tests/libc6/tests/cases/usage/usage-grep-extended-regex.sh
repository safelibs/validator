#!/usr/bin/env bash
# @testcase: usage-grep-extended-regex
# @title: grep extended regular expression
# @description: Exercises grep extended regular expression through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: grep

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-grep-extended-regex"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'a12z\nnope\n' >"$tmpdir/input.txt"
grep -E 'a[0-9]+z' "$tmpdir/input.txt" >"$tmpdir/out"
grep -Fxq 'a12z' "$tmpdir/out"

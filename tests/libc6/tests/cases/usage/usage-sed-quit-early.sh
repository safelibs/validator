#!/usr/bin/env bash
# @testcase: usage-sed-quit-early
# @title: sed quits early at address
# @description: Uses sed q to stop processing after a target line and verifies the truncated output exactly.
# @timeout: 180
# @tags: usage, sed, text
# @client: sed

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-sed-quit-early"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'one\ntwo\nthree\nfour\nfive\n' >"$tmpdir/in.txt"
sed '3q' "$tmpdir/in.txt" >"$tmpdir/out"

expected=$(printf 'one\ntwo\nthree\n')
actual=$(cat "$tmpdir/out")
test "$actual" = "$expected"

line_count=$(wc -l <"$tmpdir/out")
test "$line_count" -eq 3

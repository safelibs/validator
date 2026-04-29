#!/usr/bin/env bash
# @testcase: usage-coreutils-head-lines
# @title: coreutils head lines
# @description: Reads the first two lines of a file with head and verifies the selected output.
# @timeout: 180
# @tags: usage, coreutils, text
# @client: coreutils

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-coreutils-head-lines"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'one\ntwo\nthree\n' >"$tmpdir/in.txt"
head -n 2 "$tmpdir/in.txt" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'one'
validator_assert_contains "$tmpdir/out" 'two'

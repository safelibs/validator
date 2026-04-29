#!/usr/bin/env bash
# @testcase: usage-coreutils-fold-width
# @title: coreutils fold width
# @description: Exercises coreutils fold width through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: coreutils

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-coreutils-fold-width"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'abcdefghi\n' | fold -w 3 >"$tmpdir/out"
test "$(sed -n '1p' "$tmpdir/out")" = 'abc'
test "$(sed -n '3p' "$tmpdir/out")" = 'ghi'

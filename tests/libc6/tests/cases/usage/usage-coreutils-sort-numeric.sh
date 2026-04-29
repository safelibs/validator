#!/usr/bin/env bash
# @testcase: usage-coreutils-sort-numeric
# @title: coreutils numeric sort
# @description: Exercises coreutils numeric sort through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: coreutils

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-coreutils-sort-numeric"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf '10\n2\n1\n' | sort -n >"$tmpdir/out"
test "$(sed -n '1p' "$tmpdir/out")" = '1'
test "$(sed -n '$p' "$tmpdir/out")" = '10'

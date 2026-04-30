#!/usr/bin/env bash
# @testcase: usage-bash-printf-var
# @title: bash printf -v variable assignment
# @description: Uses bash printf -v to assign a formatted integer into a named variable and verifies the exact rendered text.
# @timeout: 120
# @tags: usage, bash
# @client: bash

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bash-printf-var"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

formatted=""
printf -v formatted '%05d' 42
test "$formatted" = '00042'

printf -v hexed '%#x' 255
test "$hexed" = '0xff'

printf '%s\n%s\n' "$formatted" "$hexed" >"$tmpdir/out"
test "$(wc -l <"$tmpdir/out")" -eq 2
validator_assert_contains "$tmpdir/out" '00042'
validator_assert_contains "$tmpdir/out" '0xff'

#!/usr/bin/env bash
# @testcase: usage-coreutils-tr-delete-digits
# @title: coreutils tr delete digits
# @description: Deletes ASCII digits from input with tr -d and verifies only alphabetic characters remain.
# @timeout: 180
# @tags: usage, coreutils, text
# @client: coreutils

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-coreutils-tr-delete-digits"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'abc123def456\n' >"$tmpdir/in.txt"
tr -d '0-9' <"$tmpdir/in.txt" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'abcdef'

#!/usr/bin/env bash
# @testcase: usage-sed-delete-blank-lines
# @title: sed deletes blank lines
# @description: Removes blank lines with sed and verifies only non-empty lines remain.
# @timeout: 180
# @tags: usage, text
# @client: sed

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-sed-delete-blank-lines"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'alpha\n\nbeta\n' | sed '/^$/d' >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'alpha'
validator_assert_contains "$tmpdir/out" 'beta'
if grep -Eq '^$' "$tmpdir/out"; then exit 1; fi

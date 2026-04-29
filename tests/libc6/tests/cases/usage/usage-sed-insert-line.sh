#!/usr/bin/env bash
# @testcase: usage-sed-insert-line
# @title: sed insert line
# @description: Inserts a line with sed and verifies the resulting text order.
# @timeout: 180
# @tags: usage, sed, text
# @client: sed

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-sed-insert-line"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'alpha\ngamma\n' >"$tmpdir/in.txt"
sed '2i beta' "$tmpdir/in.txt" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'beta'

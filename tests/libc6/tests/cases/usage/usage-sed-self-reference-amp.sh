#!/usr/bin/env bash
# @testcase: usage-sed-self-reference-amp
# @title: sed self-reference ampersand replacement
# @description: Uses sed s/regex/&/g with the & self-reference to wrap each match without losing its content.
# @timeout: 180
# @tags: usage, sed, regex
# @client: sed

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-sed-self-reference-amp"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'item 7 and item 42 here\n' | sed -E 's/[0-9]+/<&>/g' >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'item <7> and item <42> here'

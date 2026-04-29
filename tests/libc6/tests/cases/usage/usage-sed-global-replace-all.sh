#!/usr/bin/env bash
# @testcase: usage-sed-global-replace-all
# @title: sed global replace
# @description: Replaces every matching token with sed and verifies the fully rewritten output line.
# @timeout: 180
# @tags: usage, sed, text
# @client: sed

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-sed-global-replace-all"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'foo one foo two\n' >"$tmpdir/input.txt"
sed 's/foo/bar/g' "$tmpdir/input.txt" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'bar one bar two'

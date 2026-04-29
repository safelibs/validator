#!/usr/bin/env bash
# @testcase: usage-sed-global-replace
# @title: sed global replacement
# @description: Rewrites all matching tokens in a stream with sed global substitution and verifies the output text.
# @timeout: 180
# @tags: usage, cli
# @client: sed

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-sed-global-replace"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'alpha beta alpha\n' >"$tmpdir/in.txt"
sed 's/alpha/omega/g' "$tmpdir/in.txt" >"$tmpdir/out"
grep -Fxq 'omega beta omega' "$tmpdir/out"

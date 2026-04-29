#!/usr/bin/env bash
# @testcase: usage-grep-invert-match
# @title: grep inverted match
# @description: Filters text with grep -v and verifies the excluded line is absent.
# @timeout: 180
# @tags: usage, regex
# @client: grep

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-grep-invert-match"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'alpha\nskip\nbeta\n' | grep -v '^skip$' >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'alpha'
if grep -Fq 'skip' "$tmpdir/out"; then exit 1; fi

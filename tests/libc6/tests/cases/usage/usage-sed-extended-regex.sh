#!/usr/bin/env bash
# @testcase: usage-sed-extended-regex
# @title: sed extended regex rewrite
# @description: Uses sed extended regular expressions to rewrite key-value text.
# @timeout: 180
# @tags: usage, text
# @client: sed

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-sed-extended-regex"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'name: alpha\n' | sed -E 's/^([^:]+): (.*)$/\1=\2/' >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'name=alpha'

#!/usr/bin/env bash
# @testcase: usage-bash-array-length
# @title: bash array length
# @description: Reads the number of elements in a bash array and verifies the reported array length.
# @timeout: 180
# @tags: usage, bash, shell
# @client: bash

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bash-array-length"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

bash >"$tmpdir/out" <<'SH'
items=(one two three)
printf '%s\n' "${#items[@]}"
SH
validator_assert_contains "$tmpdir/out" '3'

#!/usr/bin/env bash
# @testcase: usage-bash-brace-expansion
# @title: bash brace expansion
# @description: Expands a comma-separated brace list with bash and verifies each generated token appears in the output.
# @timeout: 180
# @tags: usage, shell
# @client: bash

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bash-brace-expansion"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

bash -lc 'printf "%s\n" pre-{alpha,beta,gamma}-suffix' >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'pre-alpha-suffix'
validator_assert_contains "$tmpdir/out" 'pre-beta-suffix'
validator_assert_contains "$tmpdir/out" 'pre-gamma-suffix'

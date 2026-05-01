#!/usr/bin/env bash
# @testcase: usage-coreutils-factor-primes
# @title: coreutils factor prime decomposition
# @description: Runs coreutils factor on several inputs and verifies the integer factorizations returned through libc arbitrary-precision arithmetic helpers.
# @timeout: 120
# @tags: usage, coreutils, libc
# @client: coreutils

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-coreutils-factor-primes"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

factor 60 360 1001 97 >"$tmpdir/out"

validator_assert_contains "$tmpdir/out" '60: 2 2 3 5'
validator_assert_contains "$tmpdir/out" '360: 2 2 2 3 3 5'
validator_assert_contains "$tmpdir/out" '1001: 7 11 13'
validator_assert_contains "$tmpdir/out" '97: 97'

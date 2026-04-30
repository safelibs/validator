#!/usr/bin/env bash
# @testcase: usage-bzip2-license-flag
# @title: bzip2 license flag
# @description: Runs bzip2 -L and verifies the license banner identifies bzip2 and Julian Seward's copyright.
# @timeout: 180
# @tags: usage, bzip2, license
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzip2-license-flag"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

bzip2 -L >"$tmpdir/out" 2>&1
validator_assert_contains "$tmpdir/out" 'bzip2'
validator_assert_contains "$tmpdir/out" 'Julian Seward'
validator_assert_contains "$tmpdir/out" 'WARRANTY'

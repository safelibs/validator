#!/usr/bin/env bash
# @testcase: usage-bzip2-short-version-flag
# @title: bzip2 short version flag
# @description: Runs bzip2 -V (short flag) and verifies the version banner identifies the block-sorting compressor.
# @timeout: 180
# @tags: usage, bzip2, version
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzip2-short-version-flag"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

bzip2 -V >"$tmpdir/out" 2>&1
validator_assert_contains "$tmpdir/out" 'bzip2'
validator_assert_contains "$tmpdir/out" 'block-sorting'
validator_assert_contains "$tmpdir/out" 'Version'

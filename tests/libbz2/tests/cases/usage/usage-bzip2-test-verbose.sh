#!/usr/bin/env bash
# @testcase: usage-bzip2-test-verbose
# @title: bzip2 test verbose
# @description: Runs bzip2 test mode with verbose output and verifies the integrity check reports success.
# @timeout: 180
# @tags: usage, bzip2, integrity
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzip2-test-verbose"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'verbose payload\n' >"$tmpdir/input.txt"
bzip2 -zk "$tmpdir/input.txt"
bzip2 -tvv "$tmpdir/input.txt.bz2" >"$tmpdir/out" 2>&1
validator_assert_contains "$tmpdir/out" 'ok'

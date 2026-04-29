#!/usr/bin/env bash
# @testcase: usage-coreutils-uniq-count
# @title: coreutils uniq count
# @description: Counts repeated lines with uniq -c and verifies the aggregate count.
# @timeout: 180
# @tags: usage, coreutils, text
# @client: coreutils

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-coreutils-uniq-count"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'alpha\nalpha\nbeta\n' | uniq -c >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" '2 alpha'

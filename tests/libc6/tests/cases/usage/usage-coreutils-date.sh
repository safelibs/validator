#!/usr/bin/env bash
# @testcase: usage-coreutils-date
# @title: coreutils formats date
# @description: Formats a UTC timestamp with GNU date and verifies the year.
# @timeout: 120
# @tags: usage, cli
# @client: coreutils

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-coreutils-date"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

date -u -d '@0' '+year=%Y' >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'year=1970'

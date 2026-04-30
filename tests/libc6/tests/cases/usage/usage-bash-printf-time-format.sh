#!/usr/bin/env bash
# @testcase: usage-bash-printf-time-format
# @title: bash printf time format directive
# @description: Formats a fixed epoch timestamp with the bash printf %(...)T directive in UTC and verifies the rendered date.
# @timeout: 180
# @tags: usage, bash, shell
# @client: bash

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bash-printf-time-format"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# 1700000000 epoch seconds is 2023-11-14T22:13:20Z.
TZ=UTC printf '%(%Y-%m-%d)T\n' 1700000000 >"$tmpdir/date.out"
TZ=UTC printf '%(%H:%M:%S)T\n' 1700000000 >"$tmpdir/time.out"

validator_assert_contains "$tmpdir/date.out" '2023-11-14'
validator_assert_contains "$tmpdir/time.out" '22:13:20'

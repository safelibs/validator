#!/usr/bin/env bash
# @testcase: usage-coreutils-stat-size-format-batch11
# @title: coreutils stat size format
# @description: Formats a file size through coreutils stat.
# @timeout: 180
# @tags: usage, coreutils, filesystem
# @client: coreutils

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-coreutils-stat-size-format-batch11"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'abcdef' >"$tmpdir/file.txt"
stat -c 'size=%s' "$tmpdir/file.txt" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'size=6'
